import folium 
import basedosdados as bd
import pandas as pd
import h3

# Carrega os dados
query = "SELECT * FROM `rj-cor-dev.clima_pluviometro.ocorrencias_alagamento`"
proj_id = "projeto-fgv1"
alagamento_df = bd.read_sql(query, billing_project_id=proj_id)

mapa = folium.Map(location=[-22.9027800, -43.2575000],
                  zoom_start=10, tiles="cartodb positron")

for idx, row in alagamento_df.iterrows():
        folium.Circle(location=[row['latitude'], row['longitude']],
                          radius=10, color='green', fill=True).add_to(mapa)
        
hex = alagamento_df['id_h3'].value_counts()

hex = hex[0:50]

for row in hex.index:
    polygon = folium.Polygon(locations=h3.h3_to_geo_boundary(row), color='blue', fill=True, fill_color='blue', fill_opacity=0.1)
    polygon.add_to(mapa)

mapa.save('mapa_alagamentos.html')

