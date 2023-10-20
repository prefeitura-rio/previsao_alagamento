CREATE TABLE `rj-cor-dev.clima_pluviometro.ocorrencias_alagamento` AS 
SELECT 
    o.id_pop, o.data_inicio,
    o.data_fim, o.latitude, 
    o.longitude, o.gravidade,
    h3_grid.id as id_h3  
FROM 
    `rj-cor-dev.dados_mestres.h3_grid_res8` as h3_grid
    INNER JOIN `datario.adm_cor_comando.ocorrencias` as o ON ST_CONTAINS(h3_grid.geometry, ST_GEOGPOINT(CAST(o.longitude AS FLOAT64), CAST(o.latitude AS FLOAT64)))
WHERE 
    o.id_pop in (31,5,32,6)