#!/usr/bin/env python3

import unittest
from testpack_helper_library.unittests.dockertests import Test1and1Common
import time


class Test1and1Image(Test1and1Common):
    def file_mode_test(self, filename: str, mode: str):
        # Compare (eg) drwx???rw- to drwxr-xrw-
        result = self.execRun("ls -ld %s" % filename)
        self.assertFalse(
            result.find("No such file or directory") > -1,
            msg="%s is missing" % filename
        )
        for char_count in range(0, len(mode)):
            self.assertTrue(
                mode[char_count] == '?' or (mode[char_count] == result[char_count]),
                msg="%s incorrect mode: %s" % (filename, result)
            )

    def file_content_test(self, filename: str, content: list):
        result = self.execRun("cat %s" % filename)
        self.assertFalse(
            result.find("No such file or directory") > -1,
            msg="%s is missing" % filename
        )
        for search_item in content:
            self.assertTrue(
                result.find(search_item) > -1,
                msg="Missing : %s" % search_item
            )

    # <tests to run>

    def test_lsb_release(self):
        self.file_content_test(
            "/etc/debian_version", [ "8." ]
        )

    def test_git_installed(self):
        self.assertPackageIsInstalled("git")

    def test_traceroute_installed(self):
        self.assertPackageIsInstalled("traceroute")

    def test_telnet_installed(self):
        self.assertPackageIsInstalled("telnet")

    def test_nano_installed(self):
        self.assertPackageIsInstalled("nano")

    def test_mysql_client_installed(self):
        self.assertPackageIsInstalled("mysql-client")

    def test_vim_installed(self):
        self.assertPackageIsInstalled("vim")

    def test_curl_installed(self):
        self.assertPackageIsInstalled("curl")

    def test_bzip2_installed(self):
        self.assertPackageIsInstalled("bzip2")

    def test_hooks_folder(self):
        self.file_mode_test("/hooks", "drwxr-xr-x")

    def test_init_folder(self):
        self.file_mode_test("/init", "drwxr-xr-x")

    def test_init_entrypoint(self):
        self.file_mode_test("/init/entrypoint", "-rwxr-xr-x")

    def test_run(self):
        self.file_mode_test("/run", "drwxrwxrwx")

    def test_apt_lists_empty(self):
        self.assertEqual("total 0\n", self.execRun("ls -l /var/lib/apt/lists/"))

    def test_docker_logs(self):
        expected_log_lines = [
            "run-parts: executing /hooks/entrypoint-pre.d/20_customerssh_config",
            "run-parts: executing /hooks/supervisord-pre.d/20_configurability",
            "run-parts: executing /hooks/supervisord-pre.d/23_prep_cron",
        ]
        container_logs = self.container.logs().decode('utf-8')
        for expected_log_line in expected_log_lines:
            self.assertTrue(
                container_logs.find(expected_log_line) > -1,
                msg="Docker log line missing: %s from (%s)" % (expected_log_line, container_logs)
            )

    # </tests to run>

if __name__ == '__main__':
    unittest.main(verbosity=1)
