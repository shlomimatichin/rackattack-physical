all: unittest build check_convention

clean:
	sudo rm -fr build

UNITTESTS=$(shell find rackattack -name 'test_*.py' | sed 's@/@.@g' | sed 's/\(.*\)\.py/\1/' | sort)
COVERED_FILES=rackattack/physical/alloc/priority.py,rackattack/physical/dynamicconfig.py
unittest:
	UPSETO_JOIN_PYTHON_NAMESPACES=Yes PYTHONPATH=. python -m coverage run -m unittest $(UNITTESTS)
	python -m coverage report --show-missing --rcfile=coverage.config --fail-under=86 --include=$(COVERED_FILES)

check_convention:
	pep8 rackattack --max-line-length=109

.PHONY: build
build: build/rackattack.physical.egg

build/rackattack.physical.egg: rackattack/physical/main.py
	-mkdir $(@D)
	python -m upseto.packegg --entryPoint=$< --output=$@ --createDeps=$@.dep --compile_pyc --joinPythonNamespaces
-include build/rackattack.physical.egg.dep

install: build/rackattack.physical.egg
	-sudo systemctl stop rackattack-physical.service
	-sudo mkdir /usr/share/rackattack.physical
	sudo cp build/rackattack.physical.egg /usr/share/rackattack.physical
	sudo cp rackattack-physical.service /usr/lib/systemd/system/rackattack-physical.service
	sudo systemctl enable rackattack-physical.service
	if ["$(DONT_START_SERVICE)" == ""]; then sudo systemctl start rackattack-physical; fi

uninstall:
	-sudo systemctl stop rackattack-physical
	-sudo systemctl disable rackattack-physical.service
	-sudo rm -fr /usr/lib/systemd/system/rackattack-physical.service
	sudo rm -fr /usr/share/rackattack.physical
