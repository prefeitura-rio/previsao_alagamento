CREATE TABLE `rj-cor-dev.clima_pluviometro.taxa_precipitacao_estimada_alertario` AS 
SELECT
  h3_grid.id as id_h3, 
  t.acumulado_chuva_15_min,
  t.acumulado_chuva_1_h,
  t.data_particao,
  t.horario as data_hora
FROM
  `rj-cor-dev.dados_mestres.h3_grid_res8` h3_grid
  INNER JOIN `datario.clima_pluviometro.estacoes_alertario` e ON ST_CONTAINS(h3_grid.geometry, ST_GEOGPOINT(CAST(e.longitude AS FLOAT64), CAST(e.latitude AS FLOAT64)))
  INNER JOIN `datario.clima_pluviometro.taxa_precipitacao_alertario` t ON e.id_estacao = t.id_estacao