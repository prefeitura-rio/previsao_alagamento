import numpy as np
import pandas as pd
import basedosdados as bd
from sklearn.model_selection import train_test_split
from sklearn.metrics import (accuracy_score, r2_score, mean_squared_error, precision_score, recall_score,
                             confusion_matrix, matthews_corrcoef)
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import OneHotEncoder
from sklearn.preprocessing import LabelEncoder
from joblib import dump

# main_table = bd.read_sql(query=""" SELECT * FROM `rj-cor-dev.clima_pluviometro.main_table_fields_1H_mais_frequentes`"""
#                           , billing_project_id='projeto-fgv1', use_bqstorage_api=True)
# main_table.to_csv('csvs/main_table_mult_hexag.csv')

main_table = pd.read_csv("csvs/main_table_mult_hexag.csv")

main_table.fillna(0, inplace=True)

main_table['target'] = main_table['alagamento_pop'].apply(lambda x: 1 if x > 0 else 0)

main_table['id_h3'] = main_table['id_h3'].astype('category')

# Aplicar one-hot encoding na coluna 'estacao_ano'
one_hot_encoder = OneHotEncoder(sparse=False)
encoded_cols = one_hot_encoder.fit_transform(main_table[['estacao_ano']])
encoded_labels = one_hot_encoder.categories_[0]

# Adicionar as colunas codificadas ao DataFrame original
for i, label in enumerate(encoded_labels):
    main_table[f'estacao_ano_{label}'] = encoded_cols[:, i]


# Transformar a coluna id_h3 em categórica
label_encoder = LabelEncoder()
main_table['id_h3'] = label_encoder.fit_transform(main_table['id_h3'])


main_table.drop(columns=['data_hora', 'estacao_ano', 'alagamento_fim',
                         'estacoes', 'Unnamed: 0', 'alagamento_pop', 'alagamento_inicio',
                         'quinzenas', 'alagamento_lat', 'alagamento_long', 'id_alagamento',
                         'gravidade_alagamento'], inplace=True)

X = main_table.drop(columns=['target'])
y = main_table['target']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)
X_val, X_test, y_val, y_test = train_test_split(X_test, y_test, test_size=0.5, random_state=42)

rf = RandomForestClassifier(n_estimators=10, criterion='entropy')
rf.fit(X_train, y_train)

y_pred_rf = rf.predict(X_test)

print("Accuracy: ", accuracy_score(y_test, y_pred_rf))
print("R²: ", r2_score(y_test, y_pred_rf))
print("Error: ", mean_squared_error(y_test, y_pred_rf))
print("Precison: ", precision_score(y_test, y_pred_rf))
print("Recall: ", recall_score(y_test, y_pred_rf))
print("MCC: ", matthews_corrcoef(y_test, y_pred_rf))
conf = confusion_matrix(y_test, y_pred_rf)

print("confusion matrix:\n", conf)

dump(rf, "saved-models/RandomForest.joblib")