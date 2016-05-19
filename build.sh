#!/bin/bash

#读取build_config文件，初始化脚本中全局变量
function load_build_config() {
	for line in `cat ${build_path}/build_config`; #按行读取配置文件
	do 
		tmpVars=(${line//=/${seperator}}) 
		len=${#tmpVars[@]} 
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
	if [ -d ${project_source_path}/build/ ]; then
		rm -rf ${project_source_path}/build/
	fi
	if [ -d ${project_source_path}/gen/ ]; then
		rm -rf ${project_source_path}/gen/
	fi

	# replace local.properties 
	build_local_properties=${build_path}/local.properties
	project_local_properties=${project_source_path}/local.properties
	if [ -f ${project_local_properties} ]; then
		rm -rf ${project_local_properties}
	fi
	cp ${build_local_properties} ${project_local_properties}
	sed -i "" "/sdk.dir/d" ${project_local_properties}
	echo "sdk.dir=${android_sdk}" >> ${project_local_properties}
	
	# replace gradle.properties
	build_gradle_properties=${build_path}/gradle.properties
	project_gradle_properties=${project_source_path}/gradle.properties
	if [ -f ${project_gradle_properties} ]; then
		rm -rf ${project_gradle_properties}
	fi
	cp ${build_gradle_properties} ${project_gradle_properties}
	
	# replace gradle
	build_gradle_dir=${build_path}/gradle/
	project_gradle_dir=${project_source_path}/gradle/
	if [ -d ${project_gradle_dir} ]; then
		rm -rf ${project_gradle_dir}
	fi
	cp -r ${build_gradle_dir} ${project_gradle_dir}

	# replace strings.xml
	project_strings=${project_source_path}/res/values/strings.xml
	sed -i "" "s/name=\"version\">.*</name=\"version\">Version：${android_version_name}</g" ${project_strings}
	sed -i "" "s/name=\"code\">.*</name=\"code\">${android_version_name}</g" ${project_strings}
	sed -i "" "s/name=\"internal_code\">.*</name=\"internal_code\">${android_version_name}.0</g" ${project_strings}
	sed -i "" "s/name=\"app_name\">.*</name=\"app_name\">${app_name}</g" ${project_strings}

	# replace AndroidManifest.xml
	project_manifest="${project_source_path}/AndroidManifest.xml"
	sed -i "" "s/versionCode=\".*\"/versionCode=\"${android_version_code}\"/g" ${project_manifest}
	sed -i "" "s/versionName=\".*\">/versionName=\"${android_version_name}\">/g" ${project_manifest}

	# replace build.gradle
	build_build_gradle=${build_path}/build.gradle
	project_build_gradle=${project_source_path}/build.gradle
	if [ -f ${project_build_gradle} ]; then
		rm ${project_build_gradle}
	fi
	cp ${build_build_gradle} ${project_build_gradle}
	sed -i "" "s/compileSdkVersion .*/compileSdkVersion ${android_compile_sdk_version}/g" ${project_build_gradle}
	sed -i "" "s/buildToolsVersion .*/buildToolsVersion \"${android_build_tools_version}\"/g" ${project_build_gradle}
	sed -i "" "s/minSdkVersion .*/minSdkVersion ${android_min_sdk_version}/g" ${project_build_gradle}
	sed -i "" "s/targetSdkVersion .*/targetSdkVersion ${android_target_sdk_version}/g" ${project_build_gradle}
	sed -i "" "s/versionCode .*/versionCode ${android_version_code}/g" ${project_build_gradle}
	sed -i "" "s/versionName .*/versionName \"${android_version_name}\"/g" ${project_build_gradle}

}

function assemble_project() {
	if [ ! -d ${project_output_path} ]; then
		mkdir -p ${project_output_path}
	fi
    cd ${project_source_path}
    gradle assembleRelease
    cp -r ${project_source_path}/build/outputs/apk ${project_output_path}
}

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

#函数调用
load_build_config
replace_project_config
assemble_project

date_end=$(date +%s)
echo "total_time: $((date_end-date_start))s"
