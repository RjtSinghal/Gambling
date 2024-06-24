// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract GamblingGame is VRFConsumerBaseV2Plus {
    event Deposit(address depositer, uint256 amount);
    event RequestedRandomWinner(uint256 requestId);
    event WinnerAnnounced(uint256 requestId, address winner, uint256 winningAmount);

    uint256 private constant MAX_DEPOSITORS_COUNT = 10;

    // Chainlink VRF parameters
    uint256 private immutable i_subscriptionId;
    address private immutable i_vrfCoordinator; // 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
    bytes32 private immutable i_keyHash; // 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
    uint32 private immutable i_callbackGasLimit;
    uint16 private immutable i_requestConfirmations;
    uint32 private immutable i_numWords; // num of random values to request

    IERC20 public immutable i_token;

    mapping(address => bool) public tokenDeposited;
    mapping(address => uint256) public winningAmount;

    uint256 public depositersCount; // Number of depositers in current round
    address[] public depositers;
    bool public generateWinnerInProgress;
    address public admin;

    constructor(
        uint256 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords,
        address tokenAddress
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_subscriptionId = subscriptionId;
        i_vrfCoordinator = vrfCoordinator;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;
        i_numWords = numWords;

        i_token = IERC20(tokenAddress);
        admin = msg.sender;
    }

    /**
     * This function implements DEOSITS where any external user can deposit a certain amount
     * in the pot.
     * param: _amount
     */
    function deposit(uint256 _amount) external {
        if (depositersCount == MAX_DEPOSITORS_COUNT && tokenDeposited[msg.sender] == false) {
            generateWinner();
        } else {
            require(_amount > 0, "Deposit amount should be greater than 0.");

            // Make sure to approve this contract address to spend token
            bool success = i_token.transferFrom(msg.sender, address(this), _amount);

            if (success) {
                if (!tokenDeposited[msg.sender]) {
                    tokenDeposited[msg.sender] = true;
                    depositers.push(msg.sender);
                    depositersCount++;
                }
            }

            emit Deposit(msg.sender, _amount);
        }
    }

    /**
     * This function implements Generate Winner which is called either externally by any depositer or
     * internally depositers count is equal to MAX_depositers and a new depositor tries to deposit.
     * This Function also uses Chainlink VRF Randomness to generate a requestID to Chainlink SUbscription
     * and internally calls fulfillRandomWords function.
     */
    function generateWinner() public returns (uint256 requestId) {
        require(generateWinnerInProgress == false, "Winner Selection uner progress.");
        require(depositersCount == MAX_DEPOSITORS_COUNT, "Total depositers should be 10 to generate a winner.");

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: i_requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: i_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        generateWinnerInProgress = true;
        emit RequestedRandomWinner(requestId);
    }

    /**
     * This function is called internally after succesfully getting the requestID from Chainlink VRF
     * and gives a random number which will be the index of the winning depoister in our depositers
     * array.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % depositers.length;
        address winner = depositers[indexOfWinner];
        winningAmount[winner] = i_token.balanceOf(address(this));

        emit WinnerAnnounced(requestId, winner, winningAmount[winner]);

        // resetRound();
    }

    /**
     * This function implements ClaimReward functionality where the winner will be able to claim
     * its rewards.
     */
    function claimReward() external {
        // Using CEI design pattern to prevent re-entrancy attack
        uint256 amount = winningAmount[msg.sender];
        require(amount > 0, "No amount to claim.");

        winningAmount[msg.sender] = 0;
        i_token.transfer(msg.sender, amount);
    }

    /**
     * This function will reset the parameters for a new gambling round to begin.
     */
    function resetRound() external {
        require(msg.sender == admin, "Not the admin of the contract.");
        depositersCount = 0;
        generateWinnerInProgress = false;
        for (uint256 i = 0; i < depositers.length; i++) {
            tokenDeposited[depositers[i]] = false;
        }
        delete depositers;
    }
}
