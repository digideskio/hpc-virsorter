EMAIL = kyclark@email.arizona.edu
WORK = /rsgrps/bhurwitz/kyclark

clean:
	find pbs -type f -exec rm {} \;

delong-test: clean 
	rm -rf $(WORK)/delong-hot/test-out && ./controller.sh -i $(WORK)/delong-hot/test -o $(WORK)/delong-hot/test-out -g mbsulli -n delong

delong: clean 
	./controller.sh -i $(WORK)/delong-hot/fasta -o $(WORK)/delong-hot/virsorter -g mbsulli -n delong -s 1 -u 12
