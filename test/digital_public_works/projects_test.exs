defmodule DigitalPublicWorks.ProjectsTest do
  use DigitalPublicWorks.DataCase

  alias DigitalPublicWorks.Projects
  alias DigitalPublicWorks.Projects.Project
  alias DigitalPublicWorks.Posts

  describe "projects" do
    @valid_attrs %{body: "some body", title: "some title"}
    @update_attrs %{body: "some updated body", title: "some updated title"}
    @invalid_attrs %{body: nil, title: nil}

    test "list_projects/2 returns all projects" do
      project = insert(:project) |> reload()

      assert Projects.list_projects() == [project]
      assert Projects.list_published_projects() == []

      project = project
      |> Ecto.Changeset.change(is_public: true)
      |> Repo.update!

      assert Projects.list_projects() |> Repo.preload(:user) == [project]
      assert Projects.list_published_projects() |> Repo.preload(:user) == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = insert(:project)
      assert Projects.get_project!(project.id).id == project.id
    end

    test "create_project/1 with valid data creates a project" do
      user = insert(:user)
      assert {:ok, %Project{} = project} = Projects.create_project(user, @valid_attrs)
      assert project.body == "some body"
      assert project.title == "some title"
    end

    test "create_project/1 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(user, @invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = insert(:project)
      assert {:ok, %Project{} = project} = Projects.update_project(project, @update_attrs)
      assert project.body == "some updated body"
      assert project.title == "some updated title"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = Projects.get_project!(insert(:project).id)
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = insert(:project)
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "delete_project/1 raises error when project has followers" do
      project = insert(:project)
      user = insert(:user)

      Projects.add_follower(project, user)

      assert {:error, %Ecto.Changeset{} } = Projects.delete_project(project)
    end

    test "delete_project/1 deleting project also deletes posts" do
      %{project: project, id: post_id}  = insert(:post)

      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post_id) end
    end

    test "change_project/1 returns a project changeset" do
      project = insert(:project)
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end

    test "follow and unfollow project" do
      user = insert(:user)
      project = Projects.get_project!(insert(:project).id)

      assert Ecto.assoc(user, :followed_projects) |> Repo.all == []
      assert Projects.is_follower?(project, user) == false

      Projects.add_follower(project, user)
      assert Projects.list_followed_projects(user) == [project]
      assert Projects.is_follower?(project, user) == true

      Projects.remove_follower(project, user)
      assert Ecto.assoc(user, :followed_projects) |> Repo.all == []
      assert Projects.is_follower?(project, user) == false
    end

    test "add and remove user" do
      user = insert(:user)
      project = insert(:project) |> reload()

      assert Projects.list_joined_projects(user) == []
      assert Projects.is_user?(project, user) == false

      Projects.add_user(project, user)
      assert Projects.list_joined_projects(user) == [project |> reload()]
      assert Projects.is_user?(project, user) == true

      Projects.remove_user(project, user)
      assert Projects.list_joined_projects(user) == []
      assert Projects.is_user?(project, user) == false
    end
  end
end
