from setuptools import find_packages, setup

setup(
    name='alienhouse_employee_hub',
    version='0.1.0',
    description='AlienHouse Employee Hub for Frappe/ERPNext',
    author='AlienHouse Networks',
    author_email='connect@alienhousenetworks.com',
    packages=find_packages(include=['alienhouse_employee_hub', 'alienhouse_employee_hub.*']),
    include_package_data=True,
    zip_safe=False,
    install_requires=[],
)
