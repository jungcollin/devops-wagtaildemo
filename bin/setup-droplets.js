'use strict';

const path = require('path');
const DigitalOcean = require('do-wrapper');
const API_TOKEN = process.env.LOAD_TESTING_DIGITALOCEAN_API_TOKEN;
const api = new DigitalOcean(API_TOKEN);

const fs = require('fs');
const assert = require('assert');
const _ = require('underscore');
const merge = require('lodash.merge');
const cp = require('child_process');
const program = require('commander');
const configs = require('./droplets.config');

const DATA_BAG_SOURCE_PATH = 'data_bags/local/load-testing-generated.json';
const DATA_BAG_TARGET = { app: 'app', item: 'load-testing-generated' };

program
    .version('0.0.1')
    .option('-t, --type [type]', 'Type of knife solo command', 'bootstrap')
    .option('-s, --strategy [strategy]', 'Choose kind of strategy which used to deploy', 'default')
    .option('-d, --data-bag [data-bag]', 'Path to the data bag source', DATA_BAG_SOURCE_PATH)
    .parse(process.argv);


assert(API_TOKEN, 'Missing process.env.LOAD_TESTING_DIGITALOCEAN_API_TOKEN');


/**
 * Find config which matched with the picked up strategy
 *
 * @param  {Array}
 * @return {Object} matched config
 */
const config = _.find(configs, function(config) {
    return config.strategy === program.strategy;
});

assert(config, `Could not found the strategy "${program.strategy}" on config file`);

/**
 * Check whether that all configuration droplets have created or not
 *
 * @param  {Array}      droplets
 * @return {Boolean}    haveCreated
 */
function haveCreatedRequiredDroplets(droplets) {
    const dropletsConfig = config.droplets;
    let haveCreated = true;

    dropletsConfig.forEach(function(dropletConfig) {
        // count the created droplets and compare with the configuration
        const matched = _.filter(droplets, function(droplet) {
            return droplet.name.indexOf(dropletConfig.instanceConfig.name) !== -1;
        });

        if (matched.length < dropletConfig.amount) {
            haveCreated = false;
        }
    });

    return haveCreated;
}

function getPendingDroplets(droplets) {
    const dropletsConfig = config.droplets;
    let pendingDroplets = [];

    dropletsConfig.forEach(function(dropletConfig) {
        // count the created droplets and compare with the configuration
        const matched = _.filter(droplets, function(droplet) {
            const isPending = droplet.lock || droplet.status != 'active';
            return isPending && droplet.name.indexOf(dropletConfig.instanceConfig.name) !== -1;
        });

        pendingDroplets = pendingDroplets.concat(matched);
    });

    return pendingDroplets;
}


/**
 * Derive encrypted data bag from data bag source file & droplet's infors
 *
 * @param  {[type]} droplets [description]
 * @return {[type]}          [description]
 */
function prepareDataBagFile(droplets) {
    const dropletsConfig = config.droplets;

    const appServersConfig = _.filter(droplets, function(droplet) {
        return droplet.name.indexOf('load-testing-webapp') !== -1;
    }).map(function(droplet) {
        return `${droplet.networks['v4']['0'].ip_address}:20159`;
    });

    const appServers = _.filter(droplets, function(droplet) {
        return droplet.name.indexOf('load-testing-webapp') !== -1;
    }).map(function(droplet) {
        return droplet.networks['v4']['0'].ip_address;
    });

    const postgresqlHost = _.find(droplets, function(droplet) {
        return droplet.name.indexOf('load-testing-database') !== -1;
    }).networks['v4']['0'].ip_address;

    const redisHost = _.find(droplets, function(droplet) {
        return droplet.name.indexOf('load-testing-load-balancer') !== -1;
    }).networks['v4']['0'].ip_address;

    const loadBalancerHost = _.find(droplets, function(droplet) {
        return droplet.name.indexOf('load-testing-load-balancer') !== -1;
    }).networks['v4']['0'].ip_address;

    const frontendCacheHost = _.find(droplets, function(droplet) {
        return droplet.name.indexOf('load-testing-load-balancer') !== -1;
    }).networks['v4']['0'].ip_address;

    const configWithDroplets = {
        "frontend_server": frontendCacheHost,
        "app_servers": appServers,
        "varnish-setup": {
            "host": frontendCacheHost,
        },
        "load-balancer-setup": {
            "host": loadBalancerHost,
            "app_servers": appServersConfig
        },
        "postgresql": {
            "host": postgresqlHost
        },
        "redis": {
            "host": redisHost
        }
    };

    // fill new droplet ips into data bag file
    //
    const dataBagJSON = JSON.parse(fs.readFileSync(`${__dirname}/../chef_files/${DATA_BAG_SOURCE_PATH}`, 'utf8'));
    const dataBagStringified = JSON.stringify(merge(dataBagJSON, configWithDroplets));
    const encryptCommand = `knife solo data bag create ${DATA_BAG_TARGET.app} ${DATA_BAG_TARGET.item} --json '${dataBagStringified}'`;
    const encryptDataBag = cp.exec(encryptCommand, { cwd: './chef_files' });

    encryptDataBag.stdout.on('data', process.stderr.write);
    encryptDataBag.stderr.on('data', process.stderr.write);

    process.on('exist', function() {
        if (encryptDataBag) {
            encryptDataBag.kill('SIGTERM');
        }
    });
}

/**
 * Bootstrapping the droplets with by configured the Chef solo node path
 *
 * @param  {Array} droplets
 */
function bootstrapDroplets(droplets) {
    let cachedPreviousChildProcess = '';

    droplets.forEach(function(droplet) {
        const name = droplet.name;
        const ip = droplet.networks['v4']['0'].ip_address;

        // find the chef node path config of the droplet
        const specifiedConfig = _.find(config.droplets, function(droplet) {
            return new RegExp(`${droplet.instanceConfig.name}-\\d+$`).test(name);
        });

        if (!specifiedConfig) {
            return;
        }

        const chefNodePath = specifiedConfig.chefNodePath;
        const cookCommand = `knife solo ${program.type} root@${ip} ${chefNodePath}`;

        const chefSolo = cp.exec(cookCommand, { cwd: './chef_files' });

        chefSolo.stdout.on('data', function(x) {
            // don't print the header if previous child process is it
            if (cachedPreviousChildProcess !== name) {
                process.stdout.write(`\n\n${name.toUpperCase()}:\n`);
                cachedPreviousChildProcess = name;
            }

            process.stdout.write(x);
        });
        chefSolo.stderr.on('data', function(x) {
            process.stderr.write(x);
        });

        process.on('exist', function() {
            if (chefSolo) {
                chefSolo.kill('SIGTERM');
            }
        });
    });
}


/**
 * Empty function, do nothing, avoid calling undefined callback function
 */
function nope() {
    // intend to be empty
};


/**
 * Create droplets based on configuration
 */
function createDroplets(options) {
    options = options || {};
    const dropletsConfig = config.droplets;
    const createdDroplets = options.createdDroplets || [];

    dropletsConfig.forEach(function(dropletConfig) {
        _.range(dropletConfig.amount).forEach(function(index) {
            let instanceConfig = Object.assign(_.clone(dropletConfig.instanceConfig), {
                name: `${dropletConfig.instanceConfig.name}-${index}`
            });

            let unavailableDroplets = _.filter(createdDroplets, function(droplet) {
                return droplet.lock || droplet.status != 'active';
            });

            if (unavailableDroplets.length) {
                const dropletNames = _.pluck(unavailableDroplets, 'name').join(', ');
                console.log(`Waiting for intializing droplets: ${dropletNames}...`);
            }

            const exist = _.find(createdDroplets, function(droplet) {
                return droplet.name === instanceConfig.name;
            });

            // if the instance hasn't created yet, let do it
            if (!exist) {
                console.log(`Creating ${instanceConfig.name}...`);
                api.dropletsCreate(instanceConfig, nope);
            }
        });
    });
}

/**
 * Initial function for running all configured droplets
 */
function getOrCreateDroplets() {
    api.dropletsGetAll({}, function(error, response, data) {
        if (error) {
            return console.log(error);
        }

        const createdDroplets = data.droplets;
        const haveCreated = haveCreatedRequiredDroplets(createdDroplets);
        const pendingDroplets = getPendingDroplets(createdDroplets);

        if (haveCreated && pendingDroplets.length == 0) {
            prepareDataBagFile(createdDroplets);
            bootstrapDroplets(createdDroplets);
            console.log('Okie! Created. Now bootstrapping...')
        } else {
            if (pendingDroplets.length) {
                console.log('Waiting for pending droplets...');
                pendingDroplets.forEach(function(droplet) {
                    console.log(`  - ${droplet.name} | ${droplet.status} | ${droplet.lock}`);
                });
            } else {
                createDroplets({ createdDroplets: createdDroplets });
            }

            setTimeout(function() {
                console.log('Waiting for next 10s to retrieve droplets...');
                getOrCreateDroplets();
            }, 10000);
        }
    });
}

getOrCreateDroplets();
