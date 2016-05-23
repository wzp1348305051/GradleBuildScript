#!/bin/bash

#读取build_config文件，初始化脚本中全局变量
function init_build_config() {
	for line in `cat ${build_path}/build_config`; #按行读取配置文件
	do 
		tmpVars=(${line//=/${seperator}}) 
		# len=${#tmpVars[@]} 
		if [ ${tmpVars[0]} == "android_sdk" ];then
			android_sdk=${tmpVars[1]}
        elif [ ${tmpVars[0]} == "android_compile_sdk_version" ];then
            android_compile_sdk_version=${tmpVars[1]}
		elif [ ${tmpVars[0]} == "android_build_tools_version" ];then
			android_build_tools_version=${tmpVars[1]}
		elif [ ${tmpVars[0]} == "android_min_sdk_version" ];then
			android_min_sdk_version=${tmpVars[1]}
		elif [ ${tmpVars[0]} == "android_target_sdk_version" ];then
			android_target_sdk_version=${tmpVars[1]}	
		elif [ ${tmpVars[0]} == "android_version_code" ];then
			android_version_code=${tmpVars[1]}	
        elif [ ${tmpVars[0]} == "android_version_name" ]; then
            android_version_name=${tmpVars[1]}
		elif [ ${tmpVars[0]} == "project_source_path" ]; then
           	project_source_path=${tmpVars[1]}
		elif [ ${tmpVars[0]} == "project_output_path" ]; then
            project_output_path=${tmpVars[1]}
        elif [ ${tmpVars[0]} == "app_name" ];then
			app_name=${tmpVars[1]}
        fi
	done
}

#clean工程
function replace_project_config() {
	# clean工程
	if [ -d ${project_source_path}/build ]; then
		rm -rf ${project_source_path}/build
	fi
	if [ -d ${project_source_path}/gen ]; then
		rm -rf ${project_source_path}/gen
	fi
	if [ -d ${project_output_path} ]; then
		rm -rf ${project_output_path}
	fi

	# cpoy source code to temp directories
	global_project_temp_source_path=${project_output_path}/temp_source
	if [ ! -d ${global_project_temp_source_path} ]; then
		mkdir -p ${global_project_temp_source_path}
	fi
	cp -r ${project_source_path}/ ${global_project_temp_source_path}/

	global_project_strings_path=${global_project_temp_source_path}/res/values/strings.xml
	global_project_manifest_path=${global_project_temp_source_path}/AndroidManifest.xml
	global_project_build_gradle_path=${global_project_temp_source_path}/build.gradle

	# replace local.properties 
	build_local_properties=${build_path}/local.properties
	project_local_properties=${global_project_temp_source_path}/local.properties
	if [ -f ${project_local_properties} ]; then
		rm -f ${project_local_properties}
	fi
	cp ${build_local_properties} ${project_local_properties}
	sed -i "" "/sdk.dir/d" ${project_local_properties}
	echo "sdk.dir=${android_sdk}" >> ${project_local_properties}
	
	# replace gradle.properties
	build_gradle_properties=${build_path}/gradle.properties
	project_gradle_properties=${global_project_temp_source_path}/gradle.properties
	if [ -f ${project_gradle_properties} ]; then
		rm -f ${project_gradle_properties}
	fi
	cp ${build_gradle_properties} ${project_gradle_properties}
	
	# replace gradle
	build_gradle_path=${build_path}/gradle/
	project_gradle_path=${global_project_temp_source_path}/gradle/
	if [ -d ${project_gradle_path} ]; then
		rm -rf ${project_gradle_path}
	fi
	cp -r ${build_gradle_path} ${project_gradle_path}

	# replace res
	cp -r ${build_path}/res ${global_project_temp_source_path}

	# replace strings.xml
	sed -i "" "s/name=\"version\">.*</name=\"version\">Version：${android_version_name}</g" ${global_project_strings_path}
	sed -i "" "s/name=\"code\">.*</name=\"code\">${android_version_name}</g" ${global_project_strings_path}
	sed -i "" "s/name=\"internal_code\">.*</name=\"internal_code\">${android_version_name}.0</g" ${global_project_strings_path}
	sed -i "" "s/name=\"app_name\">.*</name=\"app_name\">${app_name}</g" ${global_project_strings_path}

	# replace AndroidManifest.xml
	sed -i "" "s/versionCode=\".*\"/versionCode=\"${android_version_code}\"/g" ${global_project_manifest_path}
	sed -i "" "s/versionName=\".*\" >/versionName=\"${android_version_name}\" >/g" ${global_project_manifest_path}

	# replace build.gradle
	build_build_gradle=${build_path}/build.gradle
	if [ -f ${global_project_build_gradle_path} ]; then
		rm ${global_project_build_gradle_path}
	fi
	cp ${build_build_gradle} ${global_project_build_gradle_path}
	sed -i "" "s/compileSdkVersion .*/compileSdkVersion ${android_compile_sdk_version}/g" ${global_project_build_gradle_path}
	sed -i "" "s/buildToolsVersion .*/buildToolsVersion \"${android_build_tools_version}\"/g" ${global_project_build_gradle_path}
	sed -i "" "s/minSdkVersion .*/minSdkVersion ${android_min_sdk_version}/g" ${global_project_build_gradle_path}
	sed -i "" "s/targetSdkVersion .*/targetSdkVersion ${android_target_sdk_version}/g" ${global_project_build_gradle_path}
	sed -i "" "s/versionCode .*/versionCode ${android_version_code}/g" ${global_project_build_gradle_path}
	sed -i "" "s/versionName .*/versionName \"${android_version_name}\"/g" ${global_project_build_gradle_path}
	sed -i "" "s/customizedChannel/${app_name}/g" ${global_project_build_gradle_path}
}

function assemble_apps() {
    if [ ! -d ${project_output_path} ]; then
        mkdir -p ${project_output_path}
    fi

    cd ${global_project_temp_source_path}
	gradle assembleRelease

	cp ${global_project_temp_source_path}/build/outputs/apk/${app_name}_${android_version_name}.apk ${project_output_path}/${app_name}_${android_version_name}.apk
	cp ${global_project_temp_source_path}/build/outputs/mapping/${app_name}/release/mapping.txt ${project_output_path}/mapping.txt
}

# 添加渠道信息
# function add_channel_info() {
# 	if [ -d ${global_project_temp_unzip_path} ]; then
# 		rm -rf ${global_project_temp_unzip_path}
# 	fi
#     mkdir -p ${global_project_temp_unzip_path}

# 	# 解压apk
# 	temp_unzip_path="${global_project_temp_unzip_path}/${app_name}_${android_version_name}"
# 	unzip -q ${global_project_temp_apk_name} -d ${temp_unzip_path}

# 	current_time=`date +%Y%m%d%H%M`
# 	final_apk_name="QingTingFm_${android_version_name}_${current_time}_${channel_letter}.apk"
# 	if [ -d ${temp_unzip_path} ]; then 
# 		channel_info_file_name="channelinfo_${channel_name}_${channel_letter}_no"
# 		touch "${temp_unzip_path}/META-INF/${channel_info_file_name}"
# 		cd ${temp_unzip_path}
# 		zip -q -r ${final_apk_name} ./ 
# 		cp ${final_apk_name} ${project_output_path}/QingTingFm_${android_version_name}_${current_time}_${channel_letter}.apk
# 	fi
# }

date_start=$(date +%s) #脚本执行开始时间
#声明全局变量
build_path=`pwd` #构建脚本所在目录
seperator=" " #分隔符

android_sdk="" #本地Android SDK路径
android_compile_sdk_version="" #gradle配置中compileSdkVersion
android_build_tools_version="" #gradle配置中buildToolsVersion
android_min_sdk_version="" #gradle配置中minSdkVersion
android_target_sdk_version="" #tgradle配置中argetSdkVersion
android_version_code="" #gradle配置中versionCode
android_version_name="" #gradle配置中versionName
project_source_path="" #工程源码目录
project_output_path="" #工程输出目录
app_name="" #app名称

global_project_temp_source_path="" #临时源代码目录，防止编译造成的更改污染源代码
global_project_strings_path="" #project下strings.xml路径
global_project_manifest_path="" #project下AndroidManifest.xml路径
global_project_build_gradle_path="" #project下build.gradle路径



#函数调用
init_build_config
replace_project_config
assemble_apps

date_end=$(date +%s)
echo "total_time: $((date_end-date_start))s"
