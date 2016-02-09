faers2csv
======
This is a set of scripts I wrote to process the drug event data download files provided by the [US FDA's open.fda.gov API](https://open.fda.gov/update/openfda-now-allows-direct-downloads-of-data/) from large JSON files into much smaller relational CSV files.

I would not recommend running these scripts on a desktop computer. Processing all 95 JSON files into 380 CSV files takes 2-3 hours on a [Digital Ocean](https://www.digitalocean.com/pricing/) virtual server with 20 cores and 64 GB RAM. The scripts use [GNU Parallel](http://www.gnu.org/software/parallel/) to process the data on all available cores in a series of pipelines. You will be downloading approximately 10 GB zipped JSON that expand to about 100 GB and this compresses down to about 800 MB as a bzipped tar ball that expands to about 6 GB in total.

## FAERS JSON
The download files are zipped JSON, broken into quarters, and seem to be capped at about 80K reports per file. The general structure of each report is [here](https://open.fda.gov/drug/event/#adverse-event-reports), and the detailed field-by-field reference is [here](https://open.fda.gov/drug/event/reference/#field-by-field-reference). My scripts break down each report into:

1. A **patient** table with header and patient demographic data
2. A **reaction** table with information on each reaction, linked back to the patient with a unique identifier (`receiptdate` and `safetyreportid`)
3. A **drug** table with information on each drug, linked back to the patient with a unique identifier (`receiptdate` and `safetyreportid`)
4. An **openfda** table with information on the *openfda* object, when present, linked back to each drug with an `md5_sum` of the object itself.

## The Pipeline

### Unzip
The zipped JSON files are unzipped in place as a stream with `unzip -p` to save space and then piped into the next stage.

### Parse JSON, Extract and Flatten, save to file as CSV
The FAERS JSON files are pretty printed, which makes them easy to read (the first hundred or so) but stream processing difficult. I use [jq](https://stedolan.github.io/jq/) to parse the JSON, extract the fields and objects of interest, flatten nested structures, and output CSV. For the **patient** and **reaction** files, we're done here. The `jq` filter for drugs concatenates all the arrays in the openfda object into ; delimited strings (I will probably need to sort before joining as well, but I haven't yet and nothing too terrible happens). The size and redundancy of the openfda objects are the main reason the JSON files are so incredibly big. The flattened JSON objects are then piped into Record Stream as newline delimited records (this is what the -c flag does).

This last point of course makes sense if you think for a minute that there are hundreds of millions of Americans who could potentially use prescription drugs, but there aren't hundreds of millions of unique drugs, in fact it looks like there are no more than maybe 9K unique representations for drug in this data and there is likely to be a fair amount of rendundancy even there. 

### Record Stream to calculate `md5_sum` for each openfda object, split into **drug** and **openfda** tables and collate **openfda**.
This step is non-trivial and I couldn't figure out how to do it in `jq`, so I used perl's [RecordStream](https://github.com/benbernard/RecordStream) to read in newline delimited JSON objects, sort the openfda fields, concatenate with ; and finally calculate an `md5_sum` as a new field. Then we split into the **drug** CSV and the **openfda** and then deduplicate the **openfda** table by counting each (useful as a checksum later).

### csvkit to fix quoting
Before writing each of the four CSVs to files, I use `csvformat` from [csvkit](https://csvkit.readthedocs.org/en/0.9.1/) to make sure that all the embedded quotes are actually doubled. The documentation for Record Stream says that it always produces "properly quoted" CSV, but I wasn't able to unambiguously figure out what that meant, and I did find some embedded quotes that weren't properly escaped in one of my earlier attempts. 

### Calculate stats, and bzip before transfer.
I use `csvstat` from Python's [csvkit](https://csvkit.readthedocs.org/en/0.9.1/) to generate reports on all of the individual CSV files (there should be 380 of them from 95 zipped JSONs) to make sure they all have the right number of columns, and that no records got lost (this is how I found out that the `safetyreportid` is not in fact unique). 

### Zip and transfer
Assuming you're running these scripts on a multi-core processor, [pbzip2](http://compression.ca/pbzip2/) lets you use them all to improve the speed of `bzip`. I use [Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader) to dump everything at the end so I can destroy the droplet as soon as posisble. 

### Optional load into PostgreSQL with pglaoder
I've also included some scripts that I use with [pgloader](http://pgloader.io/) to create tables in PostgreSQL and load the folder full of CSVs. Note that these scripts will drop any pre-existing tables that have the same names. You have been warned. 

## The Files

* **fdadl**: This is a script to download the zipped JSON from [open.fda.gov](http://open.fda.gov)
* **patientfilter.jq**: This is the `jq` script to produce the patient CSV.
* **rxnfilter.jq**: This is the `jq` script to produce the reaction CSV.
* **drugfilter.jq**: This is the `jq` script to product the intermediate drugfilter CSV.
* **faers2csv.sh**: This is the bash script that uses `parallel` to call everythign else. 
   * Make sure you've got a `downloads` folder with the zipped JSONs, empty `csv`, `drugbackup`, and `stats` folders, and the `jq` filters in the same dir you run this script from.
* **pgload.drug**: This is a command file for use with pgloader to load the drug CSVs into a PostgreSQL table of the same name. You must edit this file before running with pgloader!
* **pgload.patient**: This is a command file for use with pgloader to load the patient CSVs into a PostgreSQL table of the same name. You must edit this file before running with pgloader!
* **pgload.rxn**: This is a command file for use with pgloader to load the reaction CSVs into a PostgreSQL table of the same name. You must edit this file before running with pgloader!
* **pgload.openfda**: This is a command file for use with pgloader to load the openfda CSVs into a PostgreSQL table of the same name. You must edit this file before running with pgloader!
* **scratchpad**: This is my scratch space. ignore it. or don't.

## Sample output

Zipped output files generated on Jan 29, 2016 are available here:  https://zenodo.org/record/45589
If you find any discrepancies or errors, please submit a new issue.
