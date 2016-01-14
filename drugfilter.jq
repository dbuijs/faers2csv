# Require jq > 1.4
# Takes open.fda.gov drug event JSON and transforms into compact flat linear records suitable for Perl recs-tocsv

#start from the .results array
.results


#Creates new object with .safetyreportid string and .patient.drug array
|map(with_entries(select(.key == "safetyreportid")) + (.patient.drug[]))

# Flattens .openfda and turns openfda arrays into strings delimited with ;
|map(with_entries(select(.key != "openfda")) + (.openfda//{openfda:{"NA":"NA"}}|with_entries(.value = ([.value[]|tostring]|sort|join(";")) |.key |= "openfda_"  + .)))

#Flattens .activesubstance array
|map(with_entries(select(.key != "activesubstance")) + (.activesubstance))

#Iterates through array of objects to return a stream of objects instead of a single array
|.[]
