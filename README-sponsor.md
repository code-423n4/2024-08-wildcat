# The Wildcat Protocol

Here's the code. Enjoy it.

For other bits and pieces:

### The Whitepaper [Out Of Date For V2]

[https://tinyurl.com/wildcat-whitepaper](https://github.com/wildcat-finance/wildcat-whitepaper/blob/main/whitepaper_v1.0.pdf)

### The Manifesto 

[https://tinyurl.com/wildcat-manifesto](https://medium.com/@wildcatprotocol/the-wildcat-manifesto-db23d4b9484d)

### The V1 Documentation [Out Of Date For V2]

[https://wildcat-protocol.gitbook.io](https://wildcat-protocol.gitbook.io/wildcat/)

### Notes on memory layout

When modifying any type definition, look for any place where the type is directly accessed in yul.

Most events and errors in this contract are emitted using custom emitter functions which rely on the specific order of parameters in the definition