pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template HashLeftRight() {
    signal input left;
    signal input right;
    signal output hash;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== left;
    hasher.inputs[1] <== right;
    hash <== hasher.out;
}

template LeftRightSelector() {
    signal input ins[2];
    signal input index;
    signal output left;
    signal output right;

    signal leftIntermediate;
    signal rightIntermediate;
    // enforce index to only be 0 or 1
    index * (index - 1) === 0;

    leftIntermediate <== index * ins[0];
    left <==  leftIntermediate + (1 - index) * ins[1];

    rightIntermediate <== (1 - index) * ins[0];
    right <== rightIntermediate + index * ins[1];
}

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    component hashers[(2**n) - 1];
    signal intermediates[n-1][2**(n-1)];

    var hasherCounter = 0;

    for(var i = 0; i < (2**n)/2; i++) {
        var index = i * 2;
        hashers[hasherCounter] = HashLeftRight();
        hashers[hasherCounter].left <== leaves[index];
        hashers[hasherCounter].right <== leaves[index + 1];
        intermediates[0][i] <== hashers[hasherCounter].hash;

        hasherCounter++;
    }

    // tree depth
    // n-1 as we dont want to find the HashLeftRight of the top most layer
    for(var i = 1; i < n -1 ; i++) {
        var maxIndex = 2 ** (n - i);

        // leaf index of the level
        for(var j = 0; j < maxIndex/2; j++) {
            var index = j * 2;

            hashers[hasherCounter] = HashLeftRight();
            hashers[hasherCounter].left <== intermediates[i - 1][index];
            hashers[hasherCounter].right <== intermediates[i - 1][index + 1];
            intermediates[i][j] <== hashers[hasherCounter].hash;

            hasherCounter++;
        }  
    }

    intermediates[n-1][0] ==> root;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hashers[n];
    component leftRightSelectors[n];

    signal hashes[n + 1];
    hashes[0] <== leaf;
    for(var i = 1; i < n + 1; i++) {
        leftRightSelectors[i - 1] = LeftRightSelector();
        leftRightSelectors[i - 1].ins[0] <== hashes[i - 1];
        leftRightSelectors[i - 1].ins[1] <== path_elements[i - 1];
        leftRightSelectors[i - 1].index <== path_index[i - 1];

        hashers[i - 1] = HashLeftRight();
        hashers[i - 1].left <== leftRightSelectors[i - 1].left;
        hashers[i - 1].right <== leftRightSelectors[i - 1].right;

        hashers[i - 1].hash ==> hashes[i];
    }

    root <== hashes[n];
}