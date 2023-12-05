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
        

mapa.save('mapa_alagamentos2.html')

