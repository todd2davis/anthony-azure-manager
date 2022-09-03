#!/bin/bash
# exit code explain
# 0:finished work,successfully exit
# 1:account disabled
# 2:api not Contributor
# 3.input 0 when select vm name
# 4:dont select create VM or change vm ip

RED='\033[0;31m' # Red
NC='\033[0m' # No Color

# 检查是否安装az cli
if ! type az >/dev/null 2>&1; then
	curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

appId='自行填写'    #sharedVM appid
passwd='自行填写'       #app password
root_tenantId='自行填写'    #母号租户ID
vm_image="自行填写"

#检查母号是否登录
tenantIds=$(az account list --all --query [].tenantId -o tsv)
islogin=0
for tenantId in $tenantIds;do
        if [ $tenantId = $root_tenantId ];then
                islogin=1
                break
        fi
done

if [ $islogin = '1' ];then 
        echo '母号已经登陆'
else
        az login --service-principal -u $appId -p $passwd --tenant $root_tenantId
fi

# 登录需要操作的AZ账户
echo '请先登录 AZURE 账户:'
echo -n 'tenantid:'
read subacc_tenantId
tenantId_length=${#subacc_tenantId}
while [ $tenantId_length != '36' ];do
        echo -n '租户ID输入错误，请重新输入:'
        read subacc_tenantId
done
az login --service-principal -u $appId -p $passwd --tenant $subacc_tenantId
# 检查账户状态
subacc_status=$(az account show --query state -o tsv)
        if [ $subacc_status != 'Enabled' ];then
                echo 'azure account is DISABLED!'
                exit 1
        fi
# 检查 Contributor 权限
resourceGroup=$(az role assignment list --all --query "[?roleDefinitionName=='Contributor'].resourceGroup" -o tsv)
        if [ -z "$resourceGroup" ];then
                echo 'Contributor 权限未发现，请登录其他账号或登录官网赋予权限'
                exit 2
        fi

# 脚本功能
echo '脚本功能如下'
echo '-------------------------'
echo '1.创建虚拟机'
echo '2.更换虚拟机IP'
echo '3.查看虚拟机IP'
echo '按其余字符退出脚本'
echo '-------------------------'
echo -n '请选择操作:'
read op
# 选择创建虚拟机实例
if [ $op = '1' ];then
        echo -n '请输入实例名称(不支持特殊字符,请使用字母及数字):'
        read vm_name
        echo '1.eastasia  2.uksouth  3.koreacentral  4.japaneast  5.francecentral  6.westus3'
        echo -n '请选择区域:'
        read vm_loc
        if [ $vm_loc = '1' ];then
                vm_location='eastasia'
        elif [ $vm_loc = '2' ];then
                vm_location='uksouth'
        elif [ $vm_loc = '3' ];then
                vm_location='koreacentral'
        elif [ $vm_loc = '4' ];then
                vm_location='japaneast'
        elif [ $vm_loc = '5' ];then
                vm_location='francecentral'
        elif [ $vm_loc = '6' ];then
                vm_location='westus3'
        else
                echo '区域选择错误'
                exit 2
        fi
        # 创建虚拟机命令
        az vm create -g $resourceGroup -n $vm_name --image $vm_image --location $vm_location --public-ip-sku Basic --size Standard_B2s --specialized --authentication-type password --admin-username azureuser --admin-password 'Test1234!@#$' --public-ip-address-allocation dynamic
elif [ $op = '2' ];then
        # 列出当前账户下的虚拟机实例
        az vm list -o table
        vm_name='xxxxxxxxxxxxxxxxxxx'
        echo -n '请输入要更换IP的虚拟机名称(按0退出):'
        read vm_name
        if [ $vm_name = '0' ];then
                exit 3
        fi
        # 更换虚拟机IP，输入0时退出脚本
        while [ $vm_name != '0' ];do
                az vm deallocate -g $resourceGroup -n $vm_name
                az vm start -g $resourceGroup -n $vm_name
                echo -n '更换后的IP: '
                echo -e ${RED}$(az vm show -g $resourceGroup -n $vm_name -d --query publicIps -o tsv)
                echo -e -n ${NC}'请输入要更换IP的虚拟机名称(按0退出):'
                read vm_name
        done
elif [ $op = '3' ];then
        # 列出当前账户下的虚拟机实例
        az vm list -o table
        echo -n '请输入要看查看IP的虚拟机名称(按0退出):'
        read vm_name
        if [ $vm_name = '0' ];then
                exit 3
        fi
        while [ $vm_name != '0' ];do
		echo -n '所查虚拟机IP:'
               	echo -e ${RED}$(az vm show -g $resourceGroup -n $vm_name -d --query publicIps -o tsv)
		echo -e -n ${NC}'请输入要看查看IP的虚拟机名称(按0退出):'
                read vm_name
        done
        
else
        echo '未选择1或2，脚本停止执行'
        exit 4
fi
