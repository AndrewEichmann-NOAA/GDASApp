#!/bin/bash
set -e

project_binary_dir=$1
project_source_dir=$2

# Get low res static files from the soca sandbox
${project_source_dir}/test/soca/gw/static.sh $project_binary_dir $project_source_dir

# Stage history and restart files following the "COM" structure

COM=${project_binary_dir}/test/soca/gw/COM/gdas.20180415

mkdir -p ${COM}/06/model_data/ice/history
mkdir -p ${COM}/06/model_data/ice/restart
mkdir -p ${COM}/06/model_data/ocean/history
mkdir -p ${COM}/06/model_data/atmos/analysis

# copy CICE6 restart
ice_rst=${project_binary_dir}/test/testdata/iced.2019-04-15-43200.nc
hist_icef=${project_binary_dir}/test/testdata/cice_hist.nc

cp ${ice_rst} ${COM}/06/model_data/ice/restart/20180415.120000.cice_model.res.nc

# invent MOM6 and CICE6 history files
i=3
lof=`ls ${project_binary_dir}/test/testdata/ocn_da_*`
for ocnf in $lof; do
  cp $ocnf ${COM}/06/model_data/ocean/history/gdas.t06z.ocnf00$i.nc
  cp $hist_icef ${COM}/06/model_data/ice/history/gdas.t06z.icef00$i.nc
  i=$(($i+1))
done

# invent background error
for day in $(seq 1 2 9); do
    cp ${COM}/06/model_data/ocean/history/gdas.t06z.ocnf003.nc \
       ${project_binary_dir}/soca_static/bkgerr/stddev/ocn.ensstddev.fc.2019-04-0${day}T00:00:00Z.PT0S.nc
    cp ${project_source_dir}/soca/test/Data/72x35x25/ice.bkgerror.nc \
       ${project_binary_dir}/soca_static/bkgerr/stddev/ice.ensstddev.fc.2019-04-0${day}T00:00:00Z.PT0S.nc
done

# invent static ensemble
clim_ens_dir=${project_binary_dir}/soca_static/bkgerr/ens/2019-07-10T00Z
mkdir -p ${clim_ens_dir}
declare -A domain_long_names
domain_long_names["ocn"]="ocean"
domain_long_names["ice"]="ice"
for domain in "ocn" "ice"; do
    domain_long_name=${domain_long_names[${domain}]}
    list_of_ocn_fcst=$(ls ${COM}/06/model_data/${domain_long_name}/history/gdas.t06z.${domain}f*.nc)
    counter=1
    for file in ${list_of_ocn_fcst}; do
        file_name=${domain}.${counter}.nc
        cp ${file} ${clim_ens_dir}/${file_name}
        ((counter++))
    done
done

ice_files=$(ls ${clim_ens_dir}/ice.*.nc)
for ice_file in ${ice_files}; do
    ncrename -O -d ni,xaxis_1 -d nj,yaxis_1 -v aice_h,aicen -v hi_h,hicen -v hs_h,hsnon ${ice_file}
done
