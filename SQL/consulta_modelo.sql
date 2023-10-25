CREATE TABLE `rj-cor-dev.clima_pluviometro.main_table_fields` AS
WITH
    alertario AS ( 
    SELECT
        id_estacao,
        acumulado_chuva_15_min,
        acumulado_chuva_1_h,
        acumulado_chuva_4_h,
        acumulado_chuva_24_h,
        acumulado_chuva_96_h,
        data_particao,
        DATETIME(CONCAT(data_particao," ", horario)) AS data_update,
        FROM `datario.clima_pluviometro.taxa_precipitacao_alertario`
    ),

    h3_chuvas AS ( -- calcula qnt de chuva para cada h3
    SELECT
        h3.*,
        lm.id_estacao,
        lm.data_update,
        lm.acumulado_chuva_15_min,
        lm.acumulado_chuva_15_min/power(h3.dist,5) AS p1_15min,
        lm.acumulado_chuva_1_h,
        lm.acumulado_chuva_1_h/power(h3.dist,5) AS p1_1h,
        lm.acumulado_chuva_4_h,
        lm.acumulado_chuva_4_h/power(h3.dist,5) AS p1_4h,
        lm.acumulado_chuva_24_h,
        lm.acumulado_chuva_24_h/power(h3.dist,5) AS p1_24h,
        lm.acumulado_chuva_96_h,
        lm.acumulado_chuva_96_h/power(h3.dist,5) AS p1_96h,
        1/power(h3.dist,5) AS inv_dist
    FROM (
        WITH centroid_h3 AS (
            SELECT
                *,
                ST_CENTROID(geometry) AS geom
            FROM `rj-cor-dev.dados_mestres.h3_grid_res8`
            WHERE id = '88a8a07191fffff'
        ),

        estacoes_pluviometricas AS (
            SELECT
                id_estacao AS id,
                estacao,
                ST_GEOGPOINT(CAST(longitude AS FLOAT64),
                CAST(latitude AS FLOAT64)) AS geom
            FROM `datario.clima_pluviometro.estacoes_alertario`
        ),

        estacoes_mais_proximas AS ( -- calcula distância das estações para cada centróide do h3
            SELECT AS VALUE s
            FROM (
                SELECT
                    ARRAY_AGG(
                        STRUCT<id_h3 STRING,
                        id_estacao STRING,
                        estacao STRING,
                        dist FLOAT64>(
                        a.id, b.id, b.estacao,
                        ST_DISTANCE(a.geom, b.geom)
                        )
                      h3_media.estacoes, <> b.id
            GROUP BY a.id
            ) ab
            CROSS JOIN UNNEST(ab.ar) s
        )

        SELECT
            *,
            row_number() OVER (PARTITION BY id_h3 ORDER BY dist) AS ranking
        FROM estacoes_mais_proximas
        ORDER BY id_h3, ranking) h3
        LEFT JOIN alertario as lm
            ON lm.id_estacao=h3.id_estacao
    ),

    h3_media AS ( -- calcula média de chuva para as 3 estações mais próximas
    SELECT
        id_h3,
        data_update,
        CAST(sum(p1_15min)/sum(inv_dist) AS DECIMAL) AS chuva_15min,
        CAST(sum(p1_1h)/sum(inv_dist) AS DECIMAL) AS chuva_1h,
        CAST(sum(p1_4h)/sum(inv_dist) AS DECIMAL) AS chuva_4h,
        CAST(sum(p1_24h)/sum(inv_dist) AS DECIMAL) AS chuva_24h,
        CAST(sum(p1_96h)/sum(inv_dist) AS DECIMAL) AS chuva_96h,
        STRING_AGG(estacao ORDER BY estacao) estacoes
    FROM h3_chuvas
    WHERE ranking < 4
    GROUP BY id_h3, data_update
    )

    SELECT
        h3_media.id_h3,
        h3_media.chuva_15min AS chuva_15min,
        h3_media.chuva_1h AS chuva_1h,
        h3_media.chuva_4h AS chuva_4h,
        h3_media.chuva_24h AS chuva_24h,
        h3_media.chuva_96h AS chuva_96h,
        h3_media.data_update AS data_hora,
        CASE
            WHEN EXTRACT(MONTH FROM h3_media.data_update) = 12 AND EXTRACT(DAY FROM h3_media.data_update) >= 21 OR 
                EXTRACT(MONTH FROM h3_media.data_update) <= 3 AND EXTRACT(DAY FROM h3_media.data_update) < 21 THEN 'Verão'
            WHEN EXTRACT(MONTH FROM h3_media.data_update) = 3 AND EXTRACT(DAY FROM h3_media.data_update) >= 21 OR 
                EXTRACT(MONTH FROM h3_media.data_update) <= 6 AND EXTRACT(DAY FROM h3_media.data_update) < 21 THEN 'Outono'
            WHEN EXTRACT(MONTH FROM h3_media.data_update) = 6 AND EXTRACT(DAY FROM h3_media.data_update) >= 21 OR 
                EXTRACT(MONTH FROM h3_media.data_update) <= 9 AND EXTRACT(DAY FROM h3_media.data_update) < 23 THEN 'Inverno'
            ELSE 'Primavera'
        END AS estacao_ano,
        CONCAT('quinzena_', 
            CAST(EXTRACT(YEAR FROM h3_media.data_update) AS STRING), 
            '_',
            CAST(EXTRACT(MONTH FROM h3_media.data_update) AS STRING),
            '_',
            CASE 
            WHEN EXTRACT(DAY FROM h3_media.data_update) <= 15 THEN '1' 
            ELSE '2' 
            END
        ) AS quinzenas,
        o.id_pop AS alagamento_pop,
        o.latitude AS alagamento_lat,
        o.longitude AS alagamento_long,
        o.gravidade AS gravidade_alagamento

    FROM h3_media
    LEFT JOIN `rj-cor-dev.clima_pluviometro.ocorrencias_alagamento` AS o
        ON o.id_h3 = h3_media.id_h3 AND
        TIMESTAMP(h3_media.data_update, 'UTC-0') BETWEEN o.data_inicio AND o.data_fim
    ;