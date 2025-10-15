select TS,GpuUtil_Percent
from openrowset(
        bulk '/gpustats/gpu_stats.csv',
        data_source = 's3',
        format = 'csv',
        firstrow = 2
) WITH (
    TS datetime,
    GpuId int,
    Temperature_C int,
    GpuUtil_Percent int,
    MemUsed_MB int,
    MemTotal_MB int,
    MemUtil_Percent NVARCHAR(50) 
) as stats
order by TS desc
 