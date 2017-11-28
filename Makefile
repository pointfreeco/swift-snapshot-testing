test-linux:
	docker build --tag snapshot-testing . && \
		docker run --rm snapshot-testing
