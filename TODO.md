#  CosmosSwift

##  Merkle
Alexs-TidrM-2193:merkle $ find . | grep "go$" | grep -v _test | xargs wc {}\;
wc: {};: open: No such file or directory
X     111     455    3059 ./proof_key_path.go
     231     978    7319 ./simple_proof.go
\-      33     127    1015 ./types.go
      92     308    2410 ./proof_simple_value.go
X     138     558    4065 ./proof.go
\-      31     155    1109 ./doc.go
      94     298    2003 ./simple_map.go
\-      53     140    1258 ./result.go
\-      21      57     470 ./hash.go
\-     838    2884   19656 ./merkle.pb.go
     118     542    3599 ./simple_tree.go
\-      12      18     142 ./codec.go
    1772    6520   46105 total



simple tree:
- tree represented by an Array of leafs
- needs leafHash = hash([0] + [leaf]), innerHash = hash([1] + [left] + [right]), splitPoint of the array = largest power of 2 less than array.count
-

simple proof



simple map
- {[{k,v}], sorted}

proof

// Proof is Merkle proof defined by the list of ProofOps
Proof = [ProofOp]

// ProofOp defines an operation used for calculating Merkle root
// The data could be arbitrary format, providing nessecary data
// for example neighbouring node hash

public struct ProofOp {

public let type: String
public let key: Data
public let data: Data

}

proof simple value



proof key path



## iAVL+
Alexs-TidrM-2193:iavl $ find . | grep "go$" | grep -v _test | xargs wc {}\;
wc: {};: open: No such file or directory
     210     882    5764 ./immutable_tree.go
     163     507    3797 ./cmd/iaviewer/main.go
     580    2171   17218 ./mutable_tree.go
      37     100     750 ./version.go
     105     281    2401 ./tree_dotgraph.go
     480    1616   12760 ./nodedb.go
      11      19     129 ./logger.go
      88     319    2268 ./proof_iavl_absence.go
     499    2116   14743 ./proof_range.go
     167     525    3471 ./util.go
     192     577    4472 ./proof.go
     246     695    4471 ./common/random.go
      24      86     590 ./common/mutate.go
      62     194    1353 ./common/bytes.go
      49     177    1375 ./doc.go
     144     646    4164 ./key_format.go
      17      41     293 ./wire.go
      87     306    2146 ./proof_iavl_value.go
     453    1526   11240 ./node.go
     169     558    3804 ./proof_path.go
    3783   13342   97209 total
