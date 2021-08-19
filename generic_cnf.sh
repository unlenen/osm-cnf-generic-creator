


app_description="mysql"
app_name="mysql"
df_name="df_mysql"
helm_chart="stable/mysql"
helm_name="mysql"
network_name="mgmtnet"
network_pub_name="mgmt-ext"
service_name="demo_mysql"
vendor_name="argela"


file_vnfd="cnf/vnfd.yaml"
file_ns="ns/ns.yaml"


dir_generated="./generated"
file_generated_vnfd="${dir_generated}/vdu.yaml"
file_generated_ns="${dir_generated}/ns.yaml"


function generate_file(){

	file_org="$1"
	file_gen="$2"
	file_tmp="${2}_tmp"
 
	echo "[DEBUG][generate_file] org : $1  , new : $2 , tmp: ${file_tmp}"
	cp -R $file_org $file_tmp
	sed 's#"#\\"#g' -i $file_tmp
	eval "echo \"$(cat  ${file_tmp} )\""  > ${file_gen}
	rm -rf $file_tmp
}


function generate_cnf_data(){
	rm -rf $dir_generated
	mkdir -p $dir_generated
	generate_file $file_vnfd $file_generated_vnfd
	generate_file ${file_ns} ${file_generated_ns}
}

function osm_exists_network_function(){
	oenf_name="${1}"
	pReturn="${2}"
	oenf=$(osm nfpkg-list | grep ${oenf_name})
	if [[ ! -z "${oenf}" ]];then 
		echo "[DEBUG][OSM][NetworkFunction][AlreadyExists] name:${oenf_name}"
		eval "${pReturn}='1'"
	else
		eval "${pReturn}='0'"
	fi
}

function osm_exists_network_service(){
	oens_name="${1}"
	pReturn="${2}"
        oens=$(osm nspkg-list | grep ${oens_name})
        if [[ ! -z "${oens}" ]];then
		echo "[DEBUG][OSM][NetworkService][AlreadyExists] name:${oens_name}"
                eval "${pReturn}='1'"
	else
		eval "${pReturn}='0'"
        fi
}


function osm_save_network_function(){
	osfs_app_name="$1"
        osfs_file="$2"
        osm_exists_network_function ${osfs_app_name} pReturn_nf
        if [[ "${pReturn_nf}" -eq "1" ]];then
                echo "[DEBUG][OSM][NetworkFunction][Update] name:${osfs_app_name} file:${osfs_file}"
                osm nfpkg-update "${osfs_app_name}" --content "${osfs_file}"
        else
                echo "[DEBUG][OSM][NetworkFunction][Create] name:${osfs_app_name} file:${osfs_file}"
                osm nfpkg-create "${osfs_file}"
        fi
}


function osm_save_network_service(){
	osns_service_name="$1"
	osns_file="$2"
	osm_exists_network_service ${osns_service_name} "pReturn_nf"
        if [[ "${pReturn_nf}" -eq "1" ]];then
		echo "[DEBUG][OSM][NetworkService][Update] name:${osns_service_name} file:${osns_file}"
                osm nspkg-update "${osns_service_name}" --content "${osns_file}"
	else 
		echo "[DEBUG][OSM][NetworkService][Create] name:${osns_service_name} file:${osns_file}"
		osm nspkg-create "${osns_file}"
        fi
}

function osm_service_model_load(){
	generate_cnf_data

	osm_save_network_function "${app_name}" ${file_generated_vnfd}
	osm_save_network_service "${service_name}" ${file_generated_ns}
}

function usage(){
	echo "Generic OSM CNF Package Creator"
	echo "Usage: "
	echo "      ./generic_cnf.sh APPLICATION_NAME  APPLICATION_HELM_CHART  APPLICATION_DESCRIPTION"
}

function main(){
	osm_service_model_load
}


application_name="$1"
application_chart="$2"
application_description="$3"


if [[ -z "${application_name}" ]];then
	usage
	exit 1;
fi

if [[ -z "${application_chart}" ]];then
        usage
        exit 1;
fi

if [[ -z "${application_description}" ]];then
        usage
        exit 1;
fi


app_description="${application_description}"
app_name="cnf_${application_name}"
df_name="df_${application_name}"
helm_chart="${application_chart}"
helm_name="${application_name}"
network_name="mgmtnet"
network_pub_name="mgmt-ext"
service_name="service_${application_name}"
vendor_name="argela"


main
