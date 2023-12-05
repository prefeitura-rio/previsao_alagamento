import streamlit as st
import pandas as pd
import numpy as np
from streamlit_folium import folium_static
import folium
from folium.features import DivIcon
import basedosdados
import h3
from joblib import load
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import (confusion_matrix, fbeta_score, auc, precision_recall_curve)
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import OneHotEncoder
from sklearn.preprocessing import LabelEncoder


# Set the page title
st.set_page_config(page_title='Previsor de Alagamentos')
st.title('Teste seu modelo de previsão de alagamentos no Rio de Janeiro')

mapa = folium.Map(location=[-22.9027800, -43.2575000],
                  zoom_start=10, tiles="cartodb positron")


st.markdown("""
Faça upload de um arquivo csv com o mesmo formato encontrado em rj-cor-dev.clima_pluviometro.main_table_fields_1H_mais_frequentes, adicionando uma coluna com nome "predicted" com o resultado do seu modelo, para visualizar a performance do modelo.""")
uploaded_file = st.file_uploader("Escolha um arquivo csv", type="csv")
if uploaded_file is not None:
    main_table = pd.read_csv(uploaded_file)

    main_table.fillna(0, inplace=True)

    main_table['target'] = main_table['alagamento_pop'].apply(lambda x: 1 if x > 0 else 0)

    main_table['id_h3'] = main_table['id_h3'].astype('category')

    # Aplicar one-hot encoding na coluna 'estacao_ano'
    one_hot_encoder = OneHotEncoder(sparse=False)
    encoded_cols = one_hot_encoder.fit_transform(main_table[['estacao_ano']])
    encoded_labels = one_hot_encoder.categories_[0]

    label_encoder = LabelEncoder()

    X = main_table.drop(columns=['target', 'predicted', 'data_hora', 'estacao_ano', 'alagamento_fim',
                                 'estacoes', 'alagamento_pop', 'alagamento_inicio',
                                 'quinzenas', 'alagamento_lat', 'alagamento_long', 'id_alagamento',
                                 'gravidade_alagamento'])

    X['id_h3'] = label_encoder.fit_transform(X['id_h3'])

    # Adicionar as colunas codificadas ao DataFrame original
    for i, label in enumerate(encoded_labels):
        X[f'estacao_ano_{label}'] = encoded_cols[:, i]

    predicted = main_table['predicted']
    y = main_table['target']

    rf = load('saved-models/RandomForest.joblib')
    y_pred_rf = rf.predict(X)

    resultados = pd.DataFrame(columns=['Métrica', 'Modelo Baseline', 'Seu Modelo'])

    resultados.loc[len(resultados)] = ("F0.5: ", fbeta_score(y, y_pred_rf, beta=0.5),
                                       fbeta_score(y, main_table['predicted'], beta=0.5))
    recall_rf, precision_rf, th_rf = precision_recall_curve(y, y_pred_rf)
    recall, precision, th = precision_recall_curve(y, main_table['predicted'])
    resultados.loc[len(resultados)] = ("AUC: ", auc(recall_rf, precision_rf), auc(recall, precision))
    resultados.loc[len(resultados)] = ("Matriz de Confusão: ", (confusion_matrix(y, y_pred_rf)),
                                       (confusion_matrix(y, main_table['predicted'])))

    st.subheader('Métricas')
    st.write(resultados)

    wrong_predictions = {}
    for idx, row in main_table.iterrows():
        if row['target'] and row['predicted'] and y_pred_rf[idx]:
            folium.Circle(location=[row['alagamento_lat'], row['alagamento_long']],
                          radius=10, color='green', fill=True).add_to(mapa)
        elif row['target'] and row['predicted']:
            folium.Circle(location=[row['alagamento_lat'], row['alagamento_long']],
                          radius=10, color='blue', fill=True).add_to(mapa)
        elif row['target'] and y_pred_rf[idx]:
            folium.Circle(location=[row['alagamento_lat'], row['alagamento_long']],
                          radius=10, color='yellow', fill=True).add_to(mapa)
        elif row['target']:
            folium.Circle(location=[row['alagamento_lat'], row['alagamento_long']],
                          radius=10, color='red', fill=True).add_to(mapa)
        elif row['predicted'] or y_pred_rf[idx]:
            if row['id_h3'] in wrong_predictions.keys():
                wrong_predictions[row['id_h3']] += (row['predicted'], y_pred_rf[idx])
            else:
                wrong_predictions[row['id_h3']] = (row['predicted'], y_pred_rf[idx])
    for key, value in wrong_predictions.items():
        polygon_coord = h3.h3_to_geo_boundary(key)
        if value[1] and value[0]:
            color = 'black'
        elif value[0]:
            color = 'red'
        else:
            color = 'blue'
        polygon = folium.Polygon(locations=polygon_coord, color=color, fill=True, fill_color=color, fill_opacity=0.1)
        polygon.add_child(folium.Popup(f"Predição erradas: {value[0]}, Baseline {value[1]}"))
        polygon.add_to(mapa)

    st.subheader('Mapa de alagamentos no Rio de Janeiro')
    folium_static(mapa)

    html_code = """
      <style>
        .circle {
          width: 10px;
          height: 10px;
          border-radius: 50%;
          display: inline-block;
        }
        .hex {
          width: 10px;
          height: 10px; /* Height of the hexagon (sqrt(3)/2 * width) */
          background-color: #3498db; /* Hexagon color */
          display: inline-block;
          margin-right: 5px; /* Adjust as needed */
          clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
        }
        .row {
          display: flex;
          font-size: 0.8em;
        }

        .column {
          flex: 50%;
        }
      </style>  
    <div class="row">
    <div class="column">
    <span class="circle" style="background-color: green;"></span>: Alagamentos previstos por ambos modelos.<br>
    <span class="circle" style="background-color: red;"></span>: Alagamentos não previstos por nenhum modelo.<br>
    <span class="circle" style="background-color: blue;"></span>: Alagamentos previstos por seu modelo.<br>
    <span class="circle" style="background-color: yellow;"></span>: Alagamentos previstos pelo modelo baseline.<br>
    </div>
    <div class="column">
    <span class="hex" style="background-color: black;"></span>: Falso positivo no Hexágono (previsto por ambos modelos).<br>
    <span class="hex" style="background-color: red;"></span>: Falso positivo no Hexágono (previsto por seu modelo).<br>
    <span class="hex" style="background-color: blue;"></span>: Falso positivo no Hexágono (previsto pelo modelo baseline).<br>
    </div>
    </div >
    """

    st.markdown(html_code, unsafe_allow_html=True)


