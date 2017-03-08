class GroupMemberResource < BaseResource
  include SortableByFollowing

  attributes :rank, :created_at

  filter :rank, apply: ->(records, values, _options) {
    ranks = GroupMember.ranks.values_at(*values).compact
    ranks = values if ranks.empty?
    records.where(rank: ranks)
  }

  filters :group, :user

  has_one :group
  has_one :user
  has_many :permissions
  has_many :notes

  index UsersIndex::GroupMember
  query :query_group, apply: ->(values, _ctx) {
    { term: { group_id: values.join(' ') } }
  }
  query :query,
    mode: :query,
    apply: ->(values, _ctx) { # rubocop:disable Metrics/BlockLength
      {
        bool: {
          should: [
            {
              multi_match: {
                fields: %w[name^4 past_names],
                query: values.join(' '),
                fuzziness: 2,
                max_expansions: 15,
                prefix_length: 1
              }
            },
            {
              multi_match: {
                fields: %w[name^4 past_names],
                query: values.join(' '),
                boost: 10
              }
            },
            {
              match_phrase_prefix: {
                name: values.join(' ')
              }
            }
          ]
        }
      }
    }
end
