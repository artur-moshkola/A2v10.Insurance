//const utils = require('std:utils');
//const du = utils.date;

module.exports = {
    properties: {
        'TContract.$isOnBlank': function () {
            return this.MediaType == 'onBlank';
        },
        'TContract.$isEPolicy': function () {
            return this.MediaType == 'ePolicy';
        }
    }
};
