CREATE OR REPLACE TABLE `rj-cor-dev.clima_pluviometro.main_table_fields_1H` AS
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
                        ORDER BY ST_DISTANCE(a.geom, b.geom)
                    ) AS ar
                FROM (SELECT id, geom FROM centroid_h3) a
                CROSS JOIN(
                    SELECT id, estacao, geom
                    FROM estacoes_pluviometricas
                    WHERE geom is not null
                ) b
            WHERE a.id <> b.id
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
    ),
    media_agrupada AS (
        SELECT
            id_h3,
            data_update,
            chuva_15min,
            chuva_1h,
            chuva_4h,
            chuva_24h,
            chuva_96h,
            estacoes,
            CASE
                WHEN EXTRACT(MONTH FROM data_update) = 12 AND EXTRACT(DAY FROM data_update) >= 21 OR 
                    EXTRACT(MONTH FROM data_update) <= 3 AND EXTRACT(DAY FROM data_update) < 21 THEN 'Verão'
                WHEN EXTRACT(MONTH FROM data_update) = 3 AND EXTRACT(DAY FROM data_update) >= 21 OR 
                    EXTRACT(MONTH FROM data_update) <= 6 AND EXTRACT(DAY FROM data_update) < 21 THEN 'Outono'
                WHEN EXTRACT(MONTH FROM data_update) = 6 AND EXTRACT(DAY FROM data_update) >= 21 OR 
                    EXTRACT(MONTH FROM data_update) <= 9 AND EXTRACT(DAY FROM data_update) < 23 THEN 'Inverno'
                ELSE 'Primavera'
            END AS estacao_ano,
            CONCAT('quinzena_', 
                CAST(EXTRACT(YEAR FROM data_update) AS STRING), 
                '_',
                CAST(EXTRACT(MONTH FROM data_update) AS STRING),
                '_',
                CASE 
                WHEN EXTRACT(DAY FROM data_update) <= 15 THEN '1' 
                ELSE '2' 
                END
            ) AS quinzenas,
            TIMESTAMP_DIFF(data_update, DATETIME_TRUNC(data_update, HOUR), MINUTE) AS hora_diff
        FROM h3_media
    )

    SELECT
        media_agrupada.id_h3,
        media_agrupada.estacoes,
        media_agrupada.chuva_15min,
        media_agrupada.chuva_1h AS chuva_1h,
        media_agrupada.chuva_4h AS chuva_4h,
        media_agrupada.chuva_24h AS chuva_24h,
        media_agrupada.chuva_96h AS chuva_96h,
        media_agrupada.data_update AS data_hora,
        media_agrupada.estacao_ano,
        media_agrupada.quinzenas,
        o.data_inicio as alagamento_inicio,
        o.data_fim as alagamento_fim,
        o.id_pop AS alagamento_pop,
        o.latitude AS alagamento_lat,
        o.longitude AS alagamento_long,
        o.gravidade AS gravidade_alagamento

    FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (PARTITION BY DATETIME_TRUNC(data_update, HOUR) ORDER BY hora_diff) AS ranking_hora
        FROM
            media_agrupada
    ) as media_agrupada
    LEFT JOIN `rj-cor-dev.clima_pluviometro.ocorrencias_alagamento` AS o
        ON o.id_h3 = media_agrupada.id_h3 AND
        TIMESTAMP(media_agrupada.data_update, 'UTC-2') BETWEEN o.data_inicio AND o.data_fim
    WHERE ranking_hora = 1
    AND media_agrupada.data_update >= DATETIME('2015-1-1 00:00:00')
    ORDER BY data_hora
    ;