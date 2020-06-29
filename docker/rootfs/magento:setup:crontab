#!/bin/sh
set -e

if [ -z "${MAGENTO_CRONTAB_DISABLED}" ]; then
		MAGENTO_CRONTAB_DISABLED=false
fi

install_crontab() {
		if [ "${MAGENTO_CRONTAB_DISABLED}" = false ]; then
				echo "${DOCUMENT_ROOT}/bin/magento cron:install >/dev/null 2>&1"
				"${DOCUMENT_ROOT}"/bin/magento cron:install >/dev/null 2>&1
		fi
}

setup_crontab() {
		install_crontab
		if [ "${MAGENTO_CRONTAB_DISABLED}" = false ]; then
				echo "${DOCUMENT_ROOT}/bin/magento cron:run >/dev/null 2>&1"
				"${DOCUMENT_ROOT}"/bin/magento cron:run >/dev/null 2>&1
		fi
}