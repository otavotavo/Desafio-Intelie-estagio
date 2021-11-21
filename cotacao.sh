#!/bin/bash

RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null https://www4.bcb.gov.br/Download/fechamento/$1.csv)

if [ "$RESPONSE" -ne 200 ] ; then						#tratamento do código de resposta da requisição
	echo X
	echo Não há cotaçao no dia especificado
	exit 0
fi

curl -s -O https://www4.bcb.gov.br/Download/fechamento/$1.csv			#arquivo da cotação sendo baixado


TIPOPADRAO=A
PRIMEIRACOTACAO=$(sed -n 1p ./$1.csv | cut -d\; -f6)				#primeira cotaçao da lista
PRIMEIROPAIS=$(sed -n 1p ./$1.csv | cut -d\; -f4)				#simbolo da primeira moeda da lista


for (( i=1;  i <= $(wc -l < ./$1.csv); i++)); do
	COTACAOATUAL=$(sed -n $i\p ./$1.csv | cut -d\; -f6)
	if [ $(echo "$COTACAOATUAL < $PRIMEIRACOTACAO " | tr "," "." |  bc -l) -eq 1 ]; then		#for para conseguir a menor taxa de
		PRIMEIROPAIS=$(sed -n $i\p ./$1.csv | cut -d\; -f4)					#venda da lista
		PRIMEIRACOTACAO=$COTACAOATUAL
		TIPOPADRAO=$(sed -n $i\p ./$1.csv | cut -d\; -f3)
		INDEX=$i
	fi	
done

													#for para conseguir o nome do país
for (( i=1;  i <= $(wc -l < ./country-code-to-currency-code-mapping.csv); i++)); do			#pela  moeda
	if [ $PRIMEIROPAIS = $(sed -n $i\p ./country-code-to-currency-code-mapping.csv | cut -d , -f4) ]; then
		NOMEPAIS=$(sed -n $i\p ./country-code-to-currency-code-mapping.csv | cut -d , -f1)
	fi	
done


PARIDADEVENDA=$(sed -n $INDEX\p ./$1.csv | cut -d\; -f8 | tr "," "." | tr -d $'\r')			#tratamento a mais para eliminar o 
TAXAVENDA=$(sed -n $INDEX\p ./$1.csv | cut -d\; -f6 | tr "," ".")					#carriage return

echo "Menor cotação $PRIMEIROPAIS-$NOMEPAIS"

if [ $TIPOPADRAO == 'A' ]; then
	echo -n Cotaçao frente ao dolar:
	echo " $TAXAVENDA / $PARIDADEVENDA" | bc -l							#conta para cotaçao frente ao dólar
fi




