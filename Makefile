EMAIL = kyclark@email.arizona.edu
WORK = /rsgrps/bhurwitz/kyclark

clean:
	find . \( -name \*.conf -o -name \*.out -o -name \*.log -o -name \*.params -o -name launcher-\* \) -exec rm {} \;

delong: clean 
	./controller.sh -i $(WORK)/delong-hot/test -o $(WORK)/delong-hot/test-out -g mbsulli -n delong
