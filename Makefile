cleos = docker exec -it eosio /opt/eosio/bin/cleos --url http://127.0.0.1:7777 --wallet-url http://127.0.0.1:5555
CONTRACT_FOLDER ?= $(CURDIR)/contracts
DEV_PRIVATE_KEY ?= 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3
DEV_PUBLIC_KEY ?= EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

WALLET_PRIVATE_KEY ?= PW5JQnjzwsYawzZWvvJmYLhFyA9bBYDX8kQi3vPk5HidWEzezNRgN
WALLET_PUBLIC_KEY ?= EOS6jM6de9FnjPvZoXEPMHVx9sx7EhecpSWgwxr8yKsKpyqH39m8y

clean:
	docker rm -f eosio

eos:
	mkdir -p $(CURDIR)/contracts
	docker run --rm --name eosio \
		--publish 7777:7777 \
		--publish 127.0.0.1:5555:5555 \
		--volume $(CONTRACT_FOLDER):$(CONTRACT_FOLDER) \
		--detach \
		eosio/eos:v1.4.1 \
		/bin/bash -c \
		"keosd --http-server-address=0.0.0.0:5555 & \
		exec nodeos -e -p eosio \
			--plugin eosio::producer_plugin \
			--plugin eosio::chain_api_plugin \
			--plugin eosio::history_plugin \
			--plugin eosio::history_api_plugin \
			--plugin eosio::http_plugin \
			-d /mnt/dev/data \
			--config-dir /mnt/dev/config \
			--http-server-address=0.0.0.0:7777 \
			--access-control-allow-origin=* \
			--contracts-console \
			--http-validate-host=false \
			--filter-on='*'"

list:
	@$(cleos) wallet list

create:
	@$(cleos) wallet create --to-console
	# set WALLET_PRIVATE_KEY
	@$(cleos) wallet open

unlock:	
	@$(cleos) wallet unlock --password $(WALLET_PRIVATE_KEY)
	@$(cleos) wallet create_key
	# set WALLET_PUBLIC_KEY
	@$(cleos) wallet import --private-key $(DEV_PRIVATE_KEY)

account:
	$(cleos) create account eosio bob $(WALLET_PUBLIC_KEY)
	$(cleos) create account eosio alice $(WALLET_PUBLIC_KEY)
	$(cleos) create account eosio hello $(WALLET_PUBLIC_KEY) -p eosio@active
	$(cleos) create account eosio addressbook $(WALLET_PUBLIC_KEY) -p eosio@active
	$(cleos) create account eosio abcounter $(WALLET_PUBLIC_KEY) -p eosio@active

permission:
	@$(cleos) set account permission bob active \
		'{"threshold": 1,"keys": [{"key": "$(WALLET_PUBLIC_KEY)", "weight": 1}], "accounts": [{"permission":{"actor":"addressbook","permission":"eosio.code"},"weight":1}]}' \
		owner -p bob@owner
	
	@$(cleos) set account permission alice active \
		'{"threshold": 1,"keys": [{"key": "$(WALLET_PUBLIC_KEY)", "weight": 1}], "accounts": [{"permission":{"actor":"addressbook","permission":"eosio.code"},"weight":1}]}' \
		owner -p alice@owner

define build
	cd $(CONTRACT_FOLDER)/$(1); \
	eosio-cpp -o $(1).wasm $(1).cpp --abigen; \
	$(cleos) set contract $(1) $(CONTRACT_FOLDER)/$(1); \
	cd -
endef

hello:
	$(call build,hello)
	$(cleos) push action hello hi '["bob"]' -p bob@active
	$(cleos) push action hello hi '["alice"]' -p alice@active

ab:
	$(call build,abcounter)
	# $(cleos) push action abcounter count '["alice", "erase"]' -p alice@active
	# $(cleos) push action addressbook erase '["alice"]' -p alice@active
	# $(cleos) push action addressbook upsert '["alice", "alice", "liddell", 19, "123 drink me way", "wonderland", "amsterdam"]' -p alice@active

ab.by.count:
	$(cleos) get table abcounter abcounter counts --lower alice --limit

addr:
	$(call build,addressbook)
	$(cleos) push action addressbook upsert '["bob", "bob", "is a guy", 50, "doesnt exist", "somewhere", "someplace"]' -p bob@active
	$(cleos) push action addressbook upsert '["alice", "alice", "liddell", 9, "123 drink me way", "wonderland", "amsterdam"]' -p alice@active

addr.clean:
	$(cleos) push action addressbook erase '["bob"]' -p bob@active
	$(cleos) push action addressbook erase '["alice"]' -p alice@active

addr.by.name:
	$(cleos) get table addressbook addressbook people --lower alice --limit 1

addr.by.age:
	$(cleos) get table addressbook addressbook people --upper 10 --key-type i64 --index 2
	$(cleos) get table addressbook addressbook people --upper 50 --key-type i64 --index 2
	# $(cleos) get table addressbook addressbook people -h

addr.list:
	$(cleos) get actions alice