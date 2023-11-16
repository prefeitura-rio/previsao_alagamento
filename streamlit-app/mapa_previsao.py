import streamlit as st
import pandas as pd
import numpy as np
from streamlit_folium import folium_static
import folium
import basedosdados
import h3

# Set the page title
st.set_page_config(page_title='Previsor de Alagamentos')
st.title('Mapa de alagamentos no Rio de Janeiro')
alagamentos_df = pd.read_csv('csvs/alagamento.csv')

mapa = folium.Map(location=[-22.9027800, -43.2575000],
                  zoom_start=10, tiles="cartodb positron")
h3_uniq = alagamentos_df['h3'].unique()

for index, row in alagamentos_df.iterrows():
    folium.Circle(location=[row['latitude'], row['longitude']],
                  radius=10, color='blue', fill=True).add_to(mapa)

for id_h3 in h3_uniq:
    geo_boundary = h3.h3_to_geo_boundary(id_h3)
    # Draw the polygon on the map
    folium.Polygon(locations=geo_boundary, color='gray', fill=True).add_to(mapa)


st.subheader("""
Faça upload de um arquivo csv com as colunas latitude, longitude e target e visualize a performance do modelo.""")
uploaded_file = st.file_uploader("Escolha um arquivo csv", type="csv")
if uploaded_file is not None:
    df = pd.read_csv(uploaded_file)
    for index, row in df.iterrows():
        if (row["latitude"] in alagamentos_df['latitude'].values
                and row["longitude"] in alagamentos_df['longitude'].values):
            folium.Circle(location=[row['latitude'], row['longitude']],
                            radius=10, color='green', fill=True).add_to(mapa)
        else:
            folium.Circle(location=[row['latitude'], row['longitude']],
                            radius=10, color='red', fill=True).add_to(mapa)
    folium_static(mapa)
    st.write(df)
else:
    folium_static(mapa)
