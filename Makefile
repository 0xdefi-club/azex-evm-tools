# make deploy CHAIN_ID=<chainID>
-include .env

# Define network parameters dynamically based on chain ID
# If CHAIN_ID is not provided, NETWORK_PARAMS will be empty
NETWORK_PARAMS = $(if $(CHAIN_ID),\
	$(if $(and $(RPC_$(CHAIN_ID)),$(PRIVATE_KEY_$(CHAIN_ID))),\
		--rpc-url $(RPC_$(CHAIN_ID)) --private-key $(PRIVATE_KEY_$(CHAIN_ID)) --broadcast,\
		$(error Configuration for CHAIN_ID=$(CHAIN_ID) not found. Please check RPC_$(CHAIN_ID) and PRIVATE_KEY_$(CHAIN_ID) are set)),)

# Clean the repo
clean:
	@forge clean && rm -rf out cache

deploy:
	@time forge script script/deploy.s.sol:Deploy $(NETWORK_PARAMS) --slow -vvvv
