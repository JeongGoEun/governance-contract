pragma solidity ^0.4.24;

contract BallotEnums {
    enum BallotStates {
        Invalid,
        Ready,
        InProgress,
        Accepted,
        Rejected
    }

    enum DecisionTypes {
        Invalid,
        Accept,
        Reject
    }

    enum BallotTypes {
        Invalid,
        MemberAdd,  // new Member Address, new Node id, new Node ip, new Node port
        MemberRemoval, // old Member Address
        MemberChange,     // Old Member Address, New Member Address, new Node id, New Node ip, new Node port
        GovernanceChange, // new Governace Impl Address
        EnvValChange    // Env variable name, type , value
    }
}