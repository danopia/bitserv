require 'yaml'
require 'open-uri'

def load_api *args
	YAML.load open("http://github.com/api/v2/yaml/#{args.join '/'}").read
end

module BitServ
  class GitServ < ServicesBot
    command ['issues'], 'Return the number of open/closed issues.', 'owner/project' do |origin, params|
      open = load_api('issues', 'list', params.first, 'open')['issues']
      closed = load_api('issues', 'list', params.first, 'closed')['issues']
      
      notice origin, "#{params.first} has #{open.size} open and #{closed.size} closed issues."
      
      if open.any?
        open.sort! {|a, b| b['updated_at'] <=> a['updated_at'] }
        notice origin, "Recent issues:"
        open[0,3].each do |issue|
          p issue
          notice origin, "#{issue['number']}) #{issue['title']} (reported by #{issue['user']})"
        end
      end
    end
			
    command ['list', 'ls'], 'List the projects that a person has.', 'person' do |origin, params|
			notice origin, "#{params.first}'s Projects"
      load_api('repos', 'show', params.first)['repositories'].each do |repo|
        notice origin, repo[:name] + (repo[:fork] ? ' (fork)' : '')
      end
    end
			
    command ['info', 'show'], 'Show details about a project.', 'owner/project' do |origin, params|
      info = load_api('repos', 'show', params.first)['repository']
      notice origin, "#{info[:owner]}/#{info[:name]}: #{info[:description]} [#{info[:watchers]} watchers, #{info[:forks]} forks, #{info[:open_issues]} open issues]"
    end
	
    command ['network'], 'List all the projects in a certain project\'s network.', 'owner/project' do |origin, params|
      info = load_api('repos', 'show', params.first, 'network')
      info['network'].each do |project|
        p project
        notice origin, "#{project[:owner]}/#{project[:name]}" + (project[:fork] ? '' : ' (origin)') + ": #{project[:description]}"
      end
    end
  end
end
