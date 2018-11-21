#include <eosiolib/eosio.hpp>
#include <eosiolib/print.hpp>

using namespace eosio;

class receiver : public contract {
  public:
      using contract::contract;

      [[eosio::action]]
      void callme( name user ) {
        require_auth(user);
        print( "Call me from, ", name{user} );
      }
};
EOSIO_DISPATCH( receiver, (callme))