import os
import pytest
import json
from unittest.mock import patch, mock_open
from get_vault_key import VaultKeyManager, VaultPathNotFoundError, VaultKeyError


class TestVaultKeyManager:
  """Test cases for VaultKeyManager class."""

  def test_init_with_valid_params(self):
    """Test initialization with valid parameters."""
    # Mock the load_vault_paths method to avoid file operations
    with patch.object(VaultKeyManager, 'load_vault_paths', return_value={}):
      manager = VaultKeyManager(
        cache_dir="/tmp/cache",
        vault_paths_filename="test-paths.json",
        vault_addr="http://localhost:8200")

      assert manager.cache_dir == "/tmp/cache"
      assert manager.vault_paths_filename == "test-paths.json"
      assert manager.vault_addr == "http://localhost:8200"
      assert manager.vault_data == {}

  def test_init_without_cache_dir(self):
    """Test initialization fails when cache_dir is None."""
    with pytest.raises(ValueError, match="cache_dir cannot be None"):
      VaultKeyManager(cache_dir=None, vault_paths_filename="test-paths.json")

  def test_init_without_paths_filename(self):
    """Test initialization fails when vault_paths_filename is None."""
    with pytest.raises(ValueError,
                       match="vault_paths_filename cannot be None"):
      VaultKeyManager(cache_dir="/tmp/cache", vault_paths_filename=None)

  def test_init_with_missing_paths_file(self):
    """Test initialization when paths file doesn't exist."""
    # Mock load_vault_paths to raise VaultPathNotFoundError
    with patch.object(VaultKeyManager, 'load_vault_paths',
                      side_effect=VaultPathNotFoundError("File not found")):
      manager = VaultKeyManager(
        cache_dir="/tmp/cache", vault_paths_filename="nonexistent.json")

      assert manager.vault_data is None

  def test_init_with_corrupted_paths_file(self):
    """Test initialization when paths file is corrupted."""
    # Mock load_vault_paths to raise VaultKeyError
    with patch.object(VaultKeyManager, 'load_vault_paths',
                      side_effect=VaultKeyError("Corrupted file")):
      with pytest.raises(VaultKeyError, match="Corrupted file"):
        VaultKeyManager(
          cache_dir="/tmp/cache", vault_paths_filename="corrupted.json")

  def test_load_vault_paths_success(self):
    """Test successful loading of vault paths."""
    test_data = {"root1": {"__directories__": {}}}
    mock_file = mock_open(read_data=json.dumps(test_data))

    with patch("builtins.open", mock_file):
      manager = VaultKeyManager(
        cache_dir="/tmp/cache", vault_paths_filename="test-paths.json")
      result = manager.load_vault_paths()

      assert result == test_data

  def test_load_vault_paths_file_not_found(self):
    """Test load_vault_paths when file doesn't exist."""
    with patch("builtins.open", side_effect=FileNotFoundError):
      manager = VaultKeyManager(
        cache_dir="/tmp/cache", vault_paths_filename="test-paths.json")

      with pytest.raises(VaultPathNotFoundError):
        manager.load_vault_paths()

  def test_load_vault_paths_json_error(self):
    """Test load_vault_paths with invalid JSON."""
    mock_file = mock_open(read_data="invalid json")

    with patch("builtins.open", mock_file):
      manager = VaultKeyManager(
        cache_dir="/tmp/cache", vault_paths_filename="test-paths.json")

      with pytest.raises(VaultKeyError,
                         match="Error parsing vault paths file"):
        manager.load_vault_paths()

  def test_load_vault_paths_general_error(self):
    """Test load_vault_paths with a general exception."""
    with patch("builtins.open", side_effect=Exception("General error")):
      manager = VaultKeyManager(
        cache_dir="/tmp/cache", vault_paths_filename="test-paths.json")

      with pytest.raises(VaultKeyError, match="Error loading vault paths"):
        manager.load_vault_paths()
