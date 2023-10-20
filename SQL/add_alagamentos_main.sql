ALTER TABLE `rj-cor-dev.clima_pluviometro.main_table`
ADD COLUMN alagamento_pop INT64,
ADD COLUMN alagamento_lat FLOAT64,
ADD COLUMN alagamento_long FLOAT64,
ADD COLUMN gravidade_alagamento STRING;

UPDATE `rj-cor-dev.clima_pluviometro.main_table` AS m
SET 
    m.alagamento_pop = o.id_pop,
    m.alagamento_lat = o.latitude,
    m.alagamento_long = o.longitude,
    m.gravidade_alagamento = o.gravidade
FROM `rj-cor-dev.clima_pluviometro.ocorrencias_alagamento` AS o
WHERE 
    m.id_h3 = o.id_h3 AND
    TIMESTAMP(CONCAT(m.data_particao, ' ', m.data_hora),'UTC-3') BETWEEN o.data_inicio AND o.data_fim;