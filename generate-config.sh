#!/bin/bash

set -e

C_CONFIG="etc/config/c.defaults.properties"
CXX_CONFIG="etc/config/c++.defaults.properties"
FORT_CONFIG="etc/config/fortran.defaults.properties"

# reset our changes
sudo -Hu compiler-explorer git checkout $C_CONFIG $CXX_CONFIG $FORT_CONFIG

cce_compilers="elcc_c11911"
cxxe_compilers="elcc11911"
fe_compilers="elfortran11911"

ccs_compilers=""
cxxs_compilers=""
fs_compilers=""

maxver=0

gen_compiler()
{
	compiler=$1
	lang=$2
	dotless_ver=$3
	version=$4
	name=$5

	echo "compiler.${compiler}${lang}${dotless_ver}.semver=${version}"

	if [ -e /opt/mcst/${name}/bin.wrappers/${lang} ]; then
		echo "compiler.${compiler}${lang}${dotless_ver}.exe=/opt/mcst/${name}/bin.wrappers/${lang}"
	else
		echo "compiler.${compiler}${lang}${dotless_ver}.exe=/opt/mcst/${name}/bin/${lang}"
	fi
}

for i in /opt/mcst/*; do
	name="$(echo $i | rev | cut -d/ -f1 | rev)"

	if [[ $name != lcc-1* ]]; then
		echo "Ignoring $name, doesn't look like compiler..."
		continue
	fi

	if [ ! -d /opt/mcst/$name ]; then
		echo "Ignoring $name, not a directory..."
	fi

	version=$(echo $name | grep -oE "1\.[0-9]+\.[0-9]+")
	dotless_ver=$(echo $version | tr -d '.')

	if [[ $name == *e2k-* ]]; then
		echo "Found elbrus cross $name"
		compiler="e"
		if [[ $dotless_ver -gt $f_default ]]; then
			maxver=$dotless_ver
		fi
	elif [[ $name == *e90-r1000* ]]; then
		echo "Found sparc cross $name"
		compiler="s"
	else
		echo "Ignoring $name, unknown architecture..."
		continue
	fi


	gen_compiler "${compiler}" "lcc_c" "${dotless_ver}" "${version}" "${name}" >> $C_CONFIG
	gen_compiler "${compiler}" "lcc" "${dotless_ver}" "${version}" "${name}" >> $CXX_CONFIG
	gen_compiler "${compiler}" "lfortran" "${dotless_ver}" "${version}" "${name}" >> $FORT_CONFIG

	if [[ $compiler == e ]]; then
		cce_compilers="elcc_с${dotless_ver}:${cce_compilers}"
		cxxe_compilers="elcc${dotless_ver}:${cxxe_compilers}"
		fe_compilers="elfortran${dotless_ver}:${fe_compilers}"
	elif [[ $compiler == s ]]; then
		ccs_compilers="slcc_с${dotless_ver}:${ccs_compilers}"
		cxxs_compilers="slcc${dotless_ver}:${cxxs_compilers}"
		fs_compilers="slfortran${dotless_ver}:${fs_compilers}"
	fi
done

echo "defaultCompiler=elcc_с$maxver" >> $C_CONFIG
echo "group.slcc_с.compilers=${ccs_compilers}" >> $C_CONFIG
echo "group.elcc_с.compilers=${cce_compilers}" >> $C_CONFIG

echo "defaultCompiler=elcc$maxver" >> $CXX_CONFIG
echo "group.slcc.compilers=${cxxs_compilers}" >> $CXX_CONFIG
echo "group.elcc.compilers=${cxxe_compilers}" >> $CXX_CONFIG

echo "defaultCompiler=elfortran$maxver" >> $FORT_CONFIG
echo "group.slfortran.compilers=${fs_compilers}" >> $FORT_CONFIG
echo "group.elfortran.compilers=${fe_compilers}" >> $FORT_CONFIG
