SELECT 
    a.CompletionRate,
    a.CompletedCount,
    a.TotalCount,
    a.TotalCount - a.CompletedCount AS RemainCount,
    b.RecentAvgDuration,
    cast((a.TotalCount - a.CompletedCount) * b.RecentAvgDuration / 60.00 as int) AS PredictedRemainMinutes
FROM (
    SELECT 
        cast(100.00 * CAST(SUM(CASE WHEN embeddings IS NOT NULL THEN 1.0 ELSE 0.0 END) AS FLOAT) / COUNT(*) AS NUMERIC(28,2)) AS CompletionRate,
        SUM(CASE WHEN embeddings IS NOT NULL THEN 1 ELSE 0 END) AS CompletedCount,
        COUNT(*) AS TotalCount
    FROM [NPS_Places_Embeddings]
) a
CROSS JOIN (
    SELECT AVG(Duration) / 1000.0 AS RecentAvgDuration
    FROM (
        SELECT TOP 500 DATEDIFF(ms, 
                        LAG(embeddings_calculated) OVER (ORDER BY embeddings_calculated), 
                        embeddings_calculated) AS Duration
        FROM [NPS_Places_Embeddings]
        WHERE embeddings_calculated IS NOT NULL
        ORDER BY embeddings_calculated DESC
    ) x
    WHERE Duration < 5000
) b