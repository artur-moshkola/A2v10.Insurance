//const utils = require('std:utils');
//const du = utils.date;

module.exports = {
    properties: {
        'TContract.$url': function () {
            return '/Contracts/' + this.ProductKey + '/Edit';
        }
    },
    commands: {
        createContract,
        openContract
    }
};


async function createContract() {
    var vm = this.$vm;
    var prod = await vm.$showDialog('/Contracts/browseProducts');
    var url = '/Contracts/' + prod.Key + '/Edit';
    vm.$navigate(url);
}

function openContract(contract) {
    var vm = this.$vm;
    vm.$navigate(contract.$url, contract.Id);
}