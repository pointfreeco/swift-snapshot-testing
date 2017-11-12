FROM swift:4.0

WORKDIR /package

COPY . ./

RUN swift package resolve
RUN swift package clean
CMD swift test --parallel
