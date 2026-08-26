// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FeeManager
/// @notice Administra el porcentaje de fee aplicado sobre montos, con control de acceso por owner.
/// @dev Ejemplo sanitizado con fines de demostración.
contract FeeManager {
    /// @notice Divisor base para el cálculo de fee (10000 = precisión de 0.01%)
    uint256 public constant FEE_DENOMINATOR = 10_000;

    /// @notice Fee máximo permitido, en basis points (aquí: 20% = 2000)
    uint256 public constant MAX_FEE = 2_000;

    /// @notice Dirección actual del owner del contrato
    address public owner;

    /// @notice Dirección propuesta para una futura transferencia de ownership
    address public pendingOwner;

    /// @notice Porcentaje de fee actual, en basis points
    uint256 public feePercentage;

    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event OwnershipTransferStarted(address indexed currentOwner, address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferCancelled(address indexed currentOwner, address indexed cancelledPendingOwner);

    error NotOwner();
    error NotPendingOwner();
    error FeeExceedsMaximum(uint256 requested, uint256 max);
    error ZeroAddress();
    error SameAddress();
    error NoPendingTransfer();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @param _initialFee Fee inicial en basis points (no puede superar MAX_FEE)
    constructor(uint256 _initialFee) {
        if (_initialFee > MAX_FEE) revert FeeExceedsMaximum(_initialFee, MAX_FEE);
        owner = msg.sender;
        feePercentage = _initialFee;
    }

    /// @notice Actualiza el porcentaje de fee
    /// @param _newFee Nuevo fee en basis points (no puede superar MAX_FEE)
    function updateFee(uint256 _newFee) external onlyOwner {
        if (_newFee > MAX_FEE) revert FeeExceedsMaximum(_newFee, MAX_FEE);
        uint256 oldFee = feePercentage;
        feePercentage = _newFee;
        emit FeeUpdated(oldFee, _newFee);
    }

    /// @notice Calcula el fee correspondiente a un monto dado
    /// @param amount Monto sobre el cual calcular el fee
    /// @return El fee resultante, en las mismas unidades que `amount`
    function calculateFee(uint256 amount) external view returns (uint256) {
        return (amount * feePercentage) / FEE_DENOMINATOR;
    }

    /// @notice Inicia la transferencia de ownership a una nueva dirección
    /// @dev Requiere que la nueva dirección acepte con acceptOwnership()
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        if (newOwner == owner) revert SameAddress();
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /// @notice Cancela una transferencia de ownership pendiente
    /// @dev Solo el owner actual puede cancelar; falla si no hay transferencia pendiente
    function cancelOwnershipTransfer() external onlyOwner {
        if (pendingOwner == address(0)) revert NoPendingTransfer();
        address cancelled = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferCancelled(owner, cancelled);
    }

    /// @notice Confirma la transferencia de ownership iniciada previamente
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotPendingOwner();
        address oldOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }
}
