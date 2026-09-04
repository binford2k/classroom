node default {
  notify { 'welcome from ${trusted[certname]}':
    message => "Hello from ${trusted['certname']}, running \
${facts['os']['name']} ${facts['os']['release']['full']} on ${facts['os']['architecture']}.",
  }
}
