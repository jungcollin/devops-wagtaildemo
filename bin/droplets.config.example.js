
const config = {
	droplets: [{
		chefNodePath: 'nodes/remote/load-testing.load-blancer.json',
		amount: 1,
		instanceConfig: {
			name: 'load-testing-load-blancer',
			region: 'sgp1',
			image: 'ubuntu-14-04-x64',
			size: '512mb',
			ssh_keys: ['44:1c:d5:d4:b8:f3:df:83:0e:02:5a:f0:b8:de:42:ea']
		}
	}, {
		chefNodePath: 'nodes/remote/load-testing.webapp.json',
		amount: 2,
		instanceConfig: {
			name: 'load-testing-webapp',
			region: 'sgp1',
			image: 'ubuntu-14-04-x64',
			size: '512mb',
			ssh_keys: ['44:1c:d5:d4:b8:f3:df:83:0e:02:5a:f0:b8:de:42:ea']
		}
	}]
};

module.exports = config;
