# ``XCSnapshotTesting``

Powerfully flexible snapshot testing.

## Topics

### Essentials

- ``assert(of:as:serialization:record:snapshotDirectory:timeout:fileID:file:testName:line:column:)-(_,[SyncSnapshot<Input, Output>],_,_,_,_,_,_,_,_,_)``
- ``assert(of:as:serialization:record:snapshotDirectory:timeout:fileID:file:testName:line:column:)-(_,[String : SyncSnapshot<Input, Output>],_,_,_,_,_,_,_,_,_)``
- <doc:IntegratingWithTestFrameworks>
- <doc:MigrationGuides>

### Strategies

- <doc:CustomStrategies>
- ``Snapshot``
- ``DiffAttachmentGenerator``
- ``Sync``
- ``Async``

### Configuration

- ``withTestingEnvironment(_:operation:file:line:)``
- ``SnapshotEnvironment``
