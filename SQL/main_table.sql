CREATE TABLE rj-cor-dev.clima_pluviometro.main_table AS 
SELECT
  id_h3,
  acumulado_chuva_15_min,
  acumulado_chuva_1_h,
  data_particao,
  data_hora,
    CASE
    WHEN EXTRACT(MONTH FROM data_particao) = 12 AND EXTRACT(DAY FROM data_particao) >= 21 OR 
         EXTRACT(MONTH FROM data_particao) <= 3 AND EXTRACT(DAY FROM data_particao) < 21 THEN 'Verão'
    WHEN EXTRACT(MONTH FROM data_particao) = 3 AND EXTRACT(DAY FROM data_particao) >= 21 OR 
         EXTRACT(MONTH FROM data_particao) <= 6 AND EXTRACT(DAY FROM data_particao) < 21 THEN 'Outono'
    WHEN EXTRACT(MONTH FROM data_particao) = 6 AND EXTRACT(DAY FROM data_particao) >= 21 OR 
         EXTRACT(MONTH FROM data_particao) <= 9 AND EXTRACT(DAY FROM data_particao) < 23 THEN 'Inverno'
    ELSE 'Primavera'
  END AS estacao_ano,
  CONCAT('quinzena_', 
    CAST(EXTRACT(YEAR FROM data_particao) AS STRING), 
    '_',
    CAST(EXTRACT(MONTH FROM data_particao) AS STRING),
    '_',
    CASE 
      WHEN EXTRACT(DAY FROM data_particao) <= 15 THEN '1' 
      ELSE '2' 
    END
  ) AS quinzenas
FROM
  rj-cor-dev.clima_pluviometro.taxa_precipitacao_estimada_alertario