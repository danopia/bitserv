require 'yaml'
require 'open-uri'

def load_api *args
	YAML.load open("http://github.com/api/v2/yaml/#{args.join '/'}").read
end

module BitServ
  class GitServ < ServicesBot
    command 'issues', 'Return the number of open/closed issues.', 'owner/project'
    command ['list', 'ls'], 'List the projects that a person has.', 'person'
    command ['info', 'show'], 'Show details about a project.', 'owner/project'
    command 'network', 'List all the projects in a certain project\'s network.', 'owner/project'
    
    def cmd_issues origin, project
      open = load_api('issues', 'list', project, 'open')['issues']
      closed = load_api('issues', 'list', project, 'closed')['issues']
      
      notice origin, "#{project} has #{open.size} open and #{closed.size} closed issues."
      
      if open.any?
        open.sort! {|a, b| b['updated_at'] <=> a['updated_at'] }
        notice origin, "Recent issues:"
        open[0,3].each do |issue|
          p issue
          notice origin, "#{issue['number']}) #{issue['title']} (reported by #{issue['user']})"
        end
      end
    end
			
    def cmd_list origin, person
			notice origin, "#{person}'s Projects"
      load_api('repos', 'show', person)['repositories'].each do |repo|
        notice origin, repo[:name] + (repo[:fork] ? ' (fork)' : '')
      end
    end
			
    def cmd_info origin, project
      info = load_api('repos', 'show', project)['repository']
      notice origin, "#{info[:owner]}/#{info[:name]}: #{info[:description]} [#{info[:watchers]} watchers, #{info[:forks]} forks, #{info[:open_issues]} open issues]"
    end
	
    def cmd_network origin, project
      info = load_api('repos', 'show', project, 'network')
      info['network'].each do |project|
        notice origin, "#{project[:owner]}/#{project[:name]}" + (project[:fork] ? '' : ' (origin)') + ": #{project[:description]}"
      end
    end
  end
end
