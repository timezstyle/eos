#include <eosiolib/eosio.hpp>
#include <eosiolib/print.hpp>

using namespace eosio;

class caller : public contract {
  public:
      using contract::contract;

      [[eosio::action]]
      void hi( name from, name to ) {
        require_auth( from );
        print( "Hello, from:", name{from}, ", to:", name{to});
        action(
            permission_level{to, name("active")},
            name("receiver"), name("callme"),
            std::make_tuple(to)
        ).send();
      }
};
EOSIO_DISPATCH( caller, (hi))