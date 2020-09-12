defmodule SmokexWeb.PlanExecutions.Components.StatusIcon do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  def new(%PlanExecution{status: :created}) do
    content_tag('ion-icon', "", name: "remove-outline")
  end

  def new(%PlanExecution{status: :finished}) do
    content_tag('ion-icon', "", name: "checkmark-outline", class: "is-success")
  end

  def new(%PlanExecution{status: :halted}) do
    content_tag('ion-icon', "", name: "close-outline", class: "is-danger")
  end

  def new(%PlanExecution{status: :running}) do
    content_tag('ion-icon', "", name: "sync-outline", class: "icn-spinner is-info")
  end
end
