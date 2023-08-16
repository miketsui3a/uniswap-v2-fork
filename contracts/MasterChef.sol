pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;
/**
 *Submitted for verification at Arbiscan on 2021-09-20
*/

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Xbase.sol";




// MasterChef is the master of EGG. He can make Xbase and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once EGG is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of EGG
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accXbasePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accXbasePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. EGGs to distribute per block.
        uint256 lastRewardBlock; // Last block number that EGGs distribution occurs.
        uint256 accXbasePerShare; // Accumulated EGGs per share, times 1e18. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The EGG TOKEN!
    Xbase public xbase;
    // Dev address.
    address public devaddr;
    // EGG tokens created per block.
    uint256 public XbasePerBlock;
    // Deposit Fee address
    address public feeAddress;
    // Max emission rate.
    uint256 public constant MAX_EMISSION_RATE = 2000000000000000000;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Xbase mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 XbasePerBlock);
    event addPool(
        uint256 indexed pid,
        address lpToken,
        uint256 allocPoint,
        uint256 depositFeeBP
    );
    event setPool(
        uint256 indexed pid,
        address lpToken,
        uint256 allocPoint,
        uint256 depositFeeBP
    );
    event UpdateStartBlock(uint256 newStartBlock);

    constructor(
        Xbase _xbase,
        address _devaddr,
        address _feeAddress,
        uint256 _XbasePerBlock,
        uint256 _startBlock
    ) public {
        xbase = _xbase;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        XbasePerBlock = _XbasePerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function allPools()external view returns (PoolInfo[] memory){
        return poolInfo;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) external onlyOwner nonDuplicated(_lpToken) {
        // valid ERC20 token
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accXbasePerShare: 0,
                depositFeeBP: _depositFeeBP,
                lpSupply: 0
            })
        );

        emit addPool(
            poolInfo.length - 1,
            address(_lpToken),
            _allocPoint,
            _depositFeeBP
        );
    }

    // Update the given pool's Xbase allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) external onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit setPool(
            _pid,
            address(poolInfo[_pid].lpToken),
            _allocPoint,
            _depositFeeBP
        );
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    // View function to see pending Xbases on frontend.
    function pendingXbase(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accXbasePerShare = pool.accXbasePerShare;
        if (
            block.number > pool.lastRewardBlock &&
            pool.lpSupply != 0 &&
            totalAllocPoint > 0
        ) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 xbaseReward = multiplier
                .mul(XbasePerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accXbasePerShare = accXbasePerShare.add(
                xbaseReward.mul(1e18).div(pool.lpSupply)
            );
        }
        return
            user.amount.mul(accXbasePerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 xbaseReward = multiplier
            .mul(XbasePerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        xbase.mint(devaddr, xbaseReward.div(10));
        xbase.mint(address(this), xbaseReward);
        pool.accXbasePerShare = pool.accXbasePerShare.add(
            xbaseReward.mul(1e18).div(pool.lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Xbase allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accXbasePerShare)
                .div(1e18)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeXbaseTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accXbasePerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accXbasePerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeXbaseTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accXbasePerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (pool.lpSupply >= amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe xbase transfer function, just in case if rounding error causes pool to not have enough EGGs.
    function safeXbaseTransfer(address _to, uint256 _amount) internal {
        uint256 xbaseBal = xbase.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > xbaseBal) {
            transferSuccess = xbase.transfer(_to, xbaseBal);
        } else {
            transferSuccess = xbase.transfer(_to, _amount);
        }
        require(transferSuccess, "safeXbaseTransfer: transfer failed");
    }

    // Update dev address.
    function setDevAddress(address _devaddr) external {
        require(_devaddr != address(0), "!nonzero");
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "!nonzero");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _XbasePerBlock) external onlyOwner {
        require(_XbasePerBlock <= MAX_EMISSION_RATE, "Emission too high");
        massUpdatePools();
        XbasePerBlock = _XbasePerBlock;
        emit UpdateEmissionRate(msg.sender, _XbasePerBlock);
    }

    // Only update before start of farm
    function updateStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(
            block.number < startBlock,
            "cannot change start block if farm has already started"
        );
        require(
            block.number < _newStartBlock,
            "cannot set start block in the past"
        );
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = _newStartBlock;
        }
        startBlock = _newStartBlock;

        emit UpdateStartBlock(startBlock);
    }
}